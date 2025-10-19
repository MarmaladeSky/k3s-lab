# Simple K3s Lab

Here is a simple spin up script for K3s Local Lab cluster on qemu.

```shell
# Add the repo
helm repo add grafana https://grafana.github.io/helm-charts

# Install loki
helm --kubeconfig k3s.yaml install loki grafana/loki -f loki/values.yaml -n monitoring --create-namespace

# Install grafana
helm --kubeconfig k3s.yaml install grafana grafana/grafana -f grafana/values.yaml -n monitoring

# Access Grafana
export POD_NAME=$(kubectl --kubeconfig k3s.yaml get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --kubeconfig k3s.yaml --namespace monitoring port-forward $POD_NAME 3000

```
