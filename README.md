# Simple K3s Lab

Here is a simple spin up script for K3s Local Lab cluster on qemu.

```shell
# Install loki
helm --kubeconfig k3s.yaml install loki grafana/loki -f loki/values.yaml -n monitoring --create-namespace

# Install grafana
helm --kubeconfig k3s.yaml install grafana grafana/grafana -f grafana/values.yaml -n monitoring
```
