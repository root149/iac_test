00 базовые вводные
  00.00 подготовка базовой виртуальной машины для KVM, все действия выполняются в моем случае с сервера KVM
    требования
    OS ubuntu 22.04 live server
    HDD 20Gb /,/boot
    HDD 80Gb /var/lib
    RAM 4Gb
    file system btrfs без разбиения на разделы (3 раздела UEFI, / и /var/lib)
    режим установки Ubuntu Server Minimized
    обязательно установка ssh сервера
    имя темлейта tmpl-vm-ubnt-2204 -- не принципиально, будет в параметрах, можно выбрать на свой вкус
  00.01 действия выполняемые после установки базовой виртуальной машины
    apt purge snapd -y  #вырезаем snapd
    apt update          #обновляем список пакетов
    apt upgrade -y      #обновляем ОС но текущей актуальной версии
    apt install aptitude mc htop iftop vim locate        #устанавливаем требуемый минимальный набор ПО, список обуждаемый, но это мое мнение
    apt install qemu-guest-agent -y #установка агента qemu, в случаее иной виртуализации будет соответсвенно свой (так же в следующих шагах поменяется шаг создания клона и его переконфигурация
    apt-innstall nfs-common #требуется для последующией установки PV смотрящий на nfs сервер
    apt clean && apt autoremove #зачистка от старых пакетов
  00.02 через visudo добавить права пользователю toor149 права для выполнение всех комманд без ввода пароля (если придумаю, то имя пользователя можно будет менять в конфигах)
    toor149 ALL=(ALL) NOPASSWD:ALL #сомнительно, надо подумать!!!
  00.03 действия выполняемые на машине, где есть доступ к демону qemu/libvirt/kvm
    ssh-copy-id toor149@<IP_TEMPLATE_IMAGE> #это потребуется для настройки беспарольного входа на сервер
    возможно получить такое сообщение ---- /usr/bin/ssh-copy-id: ERROR: No identities found
    в этом случае выполнить
    ssh-keygen #генерация ключей для ssh
  00.04
01.00 клонирование виртуальных машин, выполняется на сервере где есть доступ к демону qemu/libvirt/kvm
  virt-clone --original tmpl-vm-ubnt-2204 --name kuber-m00 --auto-clone
  virt-clone --original tmpl-vm-ubnt-2204 --name kuber-w01 --auto-clone
  virt-clone --original tmpl-vm-ubnt-2204 --name kuber-w02 --auto-clone
  #virt-clone --original tmpl-vm-ubnt-2204 --name jenkins --auto-clone
  #virt-clone --original tmpl-vm-ubnt-2204 --name gitea --auto-clone
  #virt-clone --original tmpl-vm-ubnt-2204 --name nexus --auto-clone

  virsh setmaxmem kuber-m00 8G --config
  virsh setmem    kuber-m00 8G --config
  virsh setvcpus  kuber-m00 16 --config --maximum
  virsh setvcpus  kuber-m00 16 --config

  virsh setmaxmem kuber-w01 26G --config
  virsh setmem    kuber-w01 26G --config
  virsh setvcpus  kuber-w01 16  --config --maximum
  virsh setvcpus  kuber-w01 16  --config

  virsh setmaxmem kuber-w02 16G --config
  virsh setmem    kuber-w02 16G --config
  virsh setvcpus  kuber-w02 16  --config --maximum
  virsh setvcpus  kuber-w02 16  --config

установка ингресса для loadbalancer
https://habr.com/ru/company/X5Tech/blog/645651/
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  type: LoadBalancer
  loadBalancerIP: 192.168.6.110
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: http
      appProtocol: http
    - name: https
      port: 443
      protocol: TCP
      targetPort: https
      appProtocol: https
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

установка дашборда

https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  rules:
  - host: kubernetes-dashboard.kuber.home.local
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: kubernetes-dashboard
              port:
                number: 443
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
type: kubernetes.io/service-account-token
---

акцесс токен к дашшборду
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dahsboard get secret | grep admin-user | awk '{print $1}') | grep token:

мониторинг
https://grafana.com/docs/grafana-cloud/kubernetes-monitoring/other-methods/prometheus/prometheus_operator/
https://computingforgeeks.com/setup-prometheus-and-grafana-on-kubernetes/

установка вольюмов
https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/blob/master/charts/nfs-subdir-external-provisioner/README.md
https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm install second-nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=192.168.6.10 \
    --set nfs.path=/media/nfs \
    --set storageClass.name=fast-nfs-client \
    --set storageClass.provisionerName=k8s-sigs.io/fast-nfs-subdir-external-provisioner

установка gitea
helm repo add gitea-charts https://dl.gitea.io/charts/
helm install gitea gitea-charts/gitea




настройка инфраноды

для инфраноды дополнительно нужно установить autofs и после установки в конфигурационном файле поправить строку /net    -hosts в файле /etc/auto.master

https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-20-04-ru

установка gitea
https://linuxize.com/post/how-to-install-gitea-on-ubuntu-20-04/

установка графаны/прометея
https://medium.com/@gurpreets0610/deploy-prometheus-grafana-on-kubernetes-cluster-e8395cc16f91

установка секретов
https://external-secrets.io/v0.8.1/
