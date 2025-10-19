#!/usr/bin/env bash
set -euo pipefail
PIDS=""

cleanup() {
  trap - EXIT ERR INT TERM   # prevent recursion
  echo "Cleaning up..."
  virsh net-destroy k8s-net >/dev/null 2>&1 || true
  pkill -P $$ >/dev/null 2>&1 || true
}
trap cleanup EXIT ERR INT TERM

# arguments
RECREATE=false

for arg in "$@"; do
  if [ "$arg" == "--recreate" ]; then
    RECREATE=true
    break
  fi
done

# the IP to MAC address mapping is defined there
echo 'Starting nodes'
virsh net-destroy k8s-net || true
virsh net-create k8s-net.xml

sleep 3

# fetch image
if [ ! -f "debian-12-genericcloud-amd64-20250703-2162.qcow2" ]; then
  wget https://cloud.debian.org/images/cloud/bookworm/20250703-2162/debian-12-genericcloud-amd64-20250703-2162.qcow2
fi

function init {
  # Init throw away key
  rm ./k3s_cluster_key || true
  rm ./k3s_cluster_key.pub || true
  ssh-keygen -t ed25519 -f ./k3s_cluster_key -N ''

  # Compile the templates
  yq ".users[0].\"ssh-authorized-keys\"[1] = load_str(\"./k3s_cluster_key.pub\")" \
	  ./cloud-init/master/user-data.template > ./cloud-init/master/user-data
  yq ".users[0].\"ssh-authorized-keys\"[1] = load_str(\"./k3s_cluster_key.pub\") | .write_files[0].content = load_str(\"./k3s_cluster_key\")" \
	  ./cloud-init/worker/user-data.template > ./cloud-init/worker/user-data

  cloud-localds seed-master.iso cloud-init/master/user-data cloud-init/master/meta-data
  cloud-localds seed-worker.iso cloud-init/worker/user-data cloud-init/worker/meta-data
}

if [ "$RECREATE" = true ]; then
  init
fi


hosts=("7c:92:6e:84:1f:50" "7c:92:6e:84:1f:51" "7c:92:6e:84:1f:52" "7c:92:6e:84:1f:53")
for i in "${!hosts[@]}"; do
    if [ "$i" -eq 0 ]; then
      status="master"
    else
      status="worker"
    fi

    seed="seed-"$status".iso"

    echo "Init $status node $i: ${hosts[$i]}"

    if [ "$RECREATE" = true ]; then
      cp ./debian-12-genericcloud-amd64-20250703-2162.qcow2 ./image_$i.qcow2
    fi
    
    qemu-system-x86_64 \
      -m 4G \
      -smp 2 \
      -cpu host \
      -device virtio-net-pci,netdev=net0,mac=${hosts[$i]} \
      -netdev bridge,id=net0,br=br0 \
      -drive file=./image_$i.qcow2,if=virtio,cache=writeback,discard=ignore,format=qcow2 \
      -drive file=./$seed,media=cdrom \
      -boot d \
      -nographic \
      -machine type=pc,accel=kvm &

    PIDS="$PIDS $!"
done

# get k3s.yaml to use with `k9s --kubeconfig k3s.yaml` or `kubectl --kubeconfig k3s.yaml ...`
if [ ! -f "k3s.yaml" ] || [ "$RECREATE" = true ]; then
  while true; do
    K3S_CONFIG=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./k3s_cluster_key root@10.0.0.10 'cat /etc/rancher/k3s/k3s.yaml 2>/dev/null' || true)
    if [ -n "$K3S_CONFIG" ]; then
      echo "Got k3s config"
      break
    fi
    echo "Waiting for k3s config..." || true
    sleep 5
  done
  printf "%s" "$K3S_CONFIG" | sed 's/127\.0\.0\.1/10.0.0.10/g' > k3s.yaml
fi

wait
