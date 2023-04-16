kubectl create ns kuber-infra
kubectl apply -f jenkins-claim.yaml -n kuber-infra
kubectl apply -f jenkins-service.yaml -n kuber-infra
kubectl apply -f jenkins.yaml -n kuber-infra
