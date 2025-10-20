# Simple K3s Lab

Here is a simple spin up script for K3s Local Lab cluster on qemu.

```shell
# Add the repo
helm repo add grafana https://grafana.github.io/helm-charts

# Install loki
helm --kubeconfig k3s.yaml install loki grafana/loki -f loki/values.yaml -n monitoring --create-namespace

# Install grafana
helm --kubeconfig k3s.yaml install grafana grafana/grafana -f grafana/values.yaml -n monitoring

# Send
curl -H "Content-Type: application/json" -XPOST -s "http://10.0.0.10:3100/loki/api/v1/push"  \
  --data-raw "{\"streams\": [{\"stream\": {\"job\": \"test\"}, \"values\": [[\"$(date +%s)000000000\", \"fizzbuzz\"]]}]}"

# Verify
curl -v "http://10.0.0.10:3100/loki/api/v1/query_range" --data-urlencode 'query={job="test"}' | jq .data.result
```
