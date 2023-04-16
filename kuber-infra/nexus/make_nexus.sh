kubectl create ns kuber-infra
kubectl apply -f nexus-claim.yaml -n  kuber-infra
kubectl apply -f nexus-service.yaml -n  kuber-infra
kubectl apply -f nexus.yaml -n  kuber-infra