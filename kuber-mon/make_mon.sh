kubectl apply -f 1.monitoring-ns.yaml
kubectl apply -f grafana-configmap.yaml
kubectl apply -f grafana-pvc.yaml
kubectl apply -f grafana-service.yaml
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-ingress.yaml
kubectl apply -f pormetheus-pvc.yaml
kubectl apply -f prometheus-configmap.yaml
kubectl apply -f prometheus-service.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-ingress.yaml


