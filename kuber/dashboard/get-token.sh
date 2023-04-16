kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dahsboard get secret | grep admin-user | awk '{print $1}') | grep token:
