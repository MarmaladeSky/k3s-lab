# Simple K3s Lab

Here is a simple spin up script for K3s Local Lab cluster on qemu.

```shell
# Add the repo
helm repo add grafana https://grafana.github.io/helm-charts

# Install loki
helm --kubeconfig k3s.yaml install loki grafana/loki -f loki/values.yaml -n monitoring --create-namespace

# Install grafana
helm --kubeconfig k3s.yaml install grafana grafana/grafana -f grafana/values.yaml -n monitoring

# Access Grafana at http://localhost:3000
kubectl --kubeconfig k3s.yaml --namespace monitoring port-forward $(kubectl --kubeconfig k3s.yaml get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}") 3000

# Test sending logs at http://localhost:3100
kubectl --kubeconfig k3s.yaml --namespace monitoring port-forward $(kubectl --kubeconfig k3s.yaml get pods --namespace monitoring -l "app.kubernetes.io/name=loki,app.kubernetes.io/component=gateway" -o jsonpath="{.items[0].metadata.name}") 3100:8080

# Send
curl -H "Content-Type: application/json" -XPOST -s "http://localhost:3100/loki/api/v1/push"  \
  --data-raw "{\"streams\": [{\"stream\": {\"job\": \"test\"}, \"values\": [[\"$(date +%s)000000000\", \"fizzbuzz\"]]}]}"

# Verify
curl -v "http://localhost:3100/loki/api/v1/query_range" --data-urlencode 'query={job="test"}' | jq .data.result
```
