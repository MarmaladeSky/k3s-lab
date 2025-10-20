# Simple K3s Lab

Here is a simple spin up script for K3s Local Lab cluster on qemu.

```shell
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
