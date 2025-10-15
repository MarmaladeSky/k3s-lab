#!/bin/sh
set -euo pipefail
PIDS=""

echo 'Starting nodes'
virsh net-destroy k8s-net || true
virsh net-create k8s-net.xml

sleep 3

# Init throw away key
rm ./k3s_cluster_key
rm ./k3s_cluster_key.pub
ssh-keygen -t ed25519 -f ./k3s_cluster_key -N ''
PUB_KEY=$(cat ./k3s_cluster_key.pub)
PRIV_KEY=$(cat ./k3s_cluster_key)

# Compile templates
yq ".users[0].\"ssh-authorized-keys\"[1] = \"$PUB_KEY\"" ./cloud-init/master/user-data.template > ./cloud-init/master/user-data
yq ".users[0].\"ssh-authorized-keys\"[1] = \"$PUB_KEY\" | .write_files[0].content = load_str(\"./k3s_cluster_key\")" ./cloud-init/worker/user-data.template > ./cloud-init/worker/user-data

cloud-localds seed-master.iso cloud-init/master/user-data cloud-init/master/meta-data
cloud-localds seed-worker.iso cloud-init/worker/user-data cloud-init/worker/meta-data

hosts=("7c:92:6e:84:1f:50" "7c:92:6e:84:1f:51" "7c:92:6e:84:1f:52" "7c:92:6e:84:1f:53")
for i in "${!hosts[@]}"; do
    if [ "$i" -eq 0 ]; then
      status="master"
    else
      status="worker"
    fi

    seed="seed-"$status".iso"

    echo "Init $status node $i: ${hosts[$i]}"

    cp ./debian-12-genericcloud-amd64-20250703-2162.qcow2 ./image_$i.qcow2
    
    qemu-system-x86_64 \
      -m 2G \
      -smp 2 \
      -device virtio-net-pci,netdev=net0,mac=${hosts[$i]} \
      -netdev bridge,id=net0,br=br0 \
      -drive file=./image_$i.qcow2,if=virtio,cache=writeback,discard=ignore,format=qcow2 \
      -drive file=./$seed,media=cdrom \
      -boot d \
      -nographic \
      -machine type=pc,accel=kvm &

    PIDS="$PIDS $!"
done

wait

cleanup() {
  echo "Cleaning up..."
  virsh net-destroy k8s-net || true
  pkill -P $$ || true
}
trap cleanup EXIT
