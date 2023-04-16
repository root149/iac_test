kubectl create namespace kuber-nfs
kubectl apply -f class-fast.yaml
kubectl apply -f class-slow.yaml
kubectl apply -f deployment-fast.yaml
kubectl apply -f deployment-slow.yaml
kubectl apply -f rbac-fast.yaml
kubectl apply -f rbac-slow.yaml
