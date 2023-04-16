kubectl create ns kuber-infra
kubectl apply -f gitea-service.yaml -n  kuber-infra
kubectl apply -f gitea.yaml -n  kuber-infra
