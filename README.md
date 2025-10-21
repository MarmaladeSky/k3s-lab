# Grafana at K3s Lab

This is my personal K3s Lab where I learn, research and experiment with Grafana Stack (and maybe something else) at K3s.

The purpose of this repo is to provide a simple K3s spin-up script with the simplest step-by-step Grafana components deployment.

Required tools: `yq-go`, `qemu`, `libvirt`, `cloud-utils`, `k9s`

```shell
# Allow the bridge for your qemu by uncommenting "allow br0" in /etc/qemu/bridge.conf

# Add the repo
helm repo add grafana https://grafana.github.io/helm-charts

# Install loki via helm
helm --kubeconfig k3s.yaml install loki grafana/loki -f loki-chart/values.yaml -n monitoring --create-namespace

# Install Grafana Operator
helm --kubeconfig k3s.yaml upgrade -i grafana-operator grafana/grafana-operator

# Install grafana via operator
kubectl --kubeconfig k3s.yaml apply -k ./grafana-operator/

# Send
curl -H "Content-Type: application/json" -XPOST -s "http://11.0.0.10:3100/loki/api/v1/push"  \
  --data-raw "{\"streams\": [{\"stream\": {\"job\": \"test\"}, \"values\": [[\"$(date +%s)000000000\", \"fizzbuzz\"]]}]}"

# Verify
curl -v "http://11.0.0.10:3100/loki/api/v1/query_range" --data-urlencode 'query={job="test"}' | jq .data.result
```
