## 00 базовые вводные
### 00.00 подготовка базовой виртуальной машины для KVM, все действия выполняются в моем случае с сервера KVM
требования
OS ubuntu 22.04 live server
HDD 20Gb /,/boot
HDD 80Gb /var/lib
RAM 4Gb
file system btrfs без разбиения на разделы (3 раздела UEFI, / и /var/lib)
режим установки Ubuntu Server Minimized
обязательно установка ssh сервера
имя темлейта tmpl-vm-ubnt-2204 -- не принципиально, будет в параметрах, можно выбрать на свой вкус

### 00.01 действия выполняемые после установки базовой виртуальной машины
apt purge snapd -y  #вырезаем snapd
apt update          #обновляем список пакетов
apt upgrade -y      #обновляем ОС но текущей актуальной версии
apt install aptitude mc htop iftop vim locate        #устанавливаем требуемый минимальный набор ПО, список обуждаемый, но это мое мнение
apt install qemu-guest-agent -y #установка агента qemu, в случаее иной виртуализации будет соответсвенно свой (так же в следующих шагах поменяется шаг создания клона и его переконфигурация
apt-innstall nfs-common #требуется для последующией установки PV смотрящий на nfs сервер
apt clean && apt autoremove #зачистка от старых пакетов

### 00.02 через visudo добавить права пользователю toor149 
права для выполнение всех комманд без ввода пароля (если придумаю, то имя пользователя можно будет менять в конфигах)
toor149 ALL=(ALL) NOPASSWD:ALL #сомнительно, надо подумать!!!

### 00.03 действия выполняемые на машине, где есть доступ к демону qemu/libvirt/kvm
ssh-copy-id toor149@<IP_TEMPLATE_IMAGE> #это потребуется для настройки беспарольного входа на сервер
возможно получить такое сообщение ---- /usr/bin/ssh-copy-id: ERROR: No identities found
в этом случае выполнить
ssh-keygen #генерация ключей для ssh

### 00.04 клонирование и настройка виртуальных машин, выполняется на сервере где есть доступ к демону qemu/libvirt/kvm
virt-clone --original tmpl-vm-ubnt-2204 --name kuber-m00 --auto-clone
virt-clone --original tmpl-vm-ubnt-2204 --name kuber-w01 --auto-clone
virt-clone --original tmpl-vm-ubnt-2204 --name kuber-w02 --auto-clone

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

### 00.05 настройка DNS/DHCP сервера (в моем случаее это dnsmasq)
#DHCP Reservation kuber cluster
dhcp-host=52:54:00:53:XX:99,192.168.6.99  #mgmt
dhcp-host=52:54:00:50:XX:00,192.168.6.100 #kuber-m00
dhcp-host=52:54:00:b0:XX:01,192.168.6.101 #kuber-w01
dhcp-host=52:54:00:06:XX:02,192.168.6.102 #kuber-w02
#настройка преобразования имен вида XXXX.kuber.home.local адрес ингресса
address=/kuber.home.local/192.168.6.13

## 01 подготовка кластера kubernetes
### 01.01 подготовка кубспрея
файл инвентаря
[all]
kuber-m00 ansible_host=192.168.6.100  
kuber-w01 ansible_host=192.168.6.101  
kuber-w02 ansible_host=192.168.6.102  
[kube_control_plane]
kuber-m00
[etcd]
kuber-m00
[kube_node]
kuber-w01
kuber-w02
[kube-ingress]
kuber-m00
[calico_rr]
[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr

файл addons
#### #включаем helm
helm_enabled: true
#### #включаем метрики
metrics_server_enabled: true
metrics_server_kubelet_insecure_tls: true
metrics_server_metric_resolution: 15s
metrics_server_kubelet_preferred_address_types: "InternalIP"
#### #включаем ингресс
ingress_nginx_enabled: true
ingress_nginx_host_network: false
ingress_publish_status_address: ""
ingress_nginx_nodeselector:
  kubernetes.io/os: "linux"
ingress_nginx_namespace: "ingress-nginx"
ingress_nginx_insecure_port: 80
ingress_nginx_secure_port: 443
ingress_nginx_configmap:
  map-hash-bucket-size: "128"
  ssl-protocols: "TLSv1.2 TLSv1.3"

#### #включаем MetalLB
metallb_enabled: true
metallb_speaker_enabled: "{{ metallb_enabled }}"
metallb_ip_range:
   \- 192.168.6.13-192.168.6.13"

### 01.02 подготовленные файлы для работы кубернетеса лежат в каталоге kuber, согласно задачам
#### csi -- настройки хранилища (создается 2 класса, быстрый и медленный нфс)
192.168.6.10:/media/nfs/kuber-nfs-fast  (nfs на ssd дисках)
192.168.6.15:/mnt/HD/HD_a2/nfs/kuber-nfs-slow
###### за основу взят мануал 
[https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)

#### dashboard -- веб консоль управления + настроены сервисы + настроены ингрессы 
#### за основу взят мануал по этой ссылке
[https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html](https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html)
#### ingress -- настройка ингресса, за основу взяты материалы лекций
#### за основу взят мануал по этой ссылке
[https://habr.com/ru/company/X5Tech/blog/645651/](https://habr.com/ru/company/X5Tech/blog/645651/)
для доступа к консоли необходимо получить токен с помощью скрипта 
get-token.sh 

## 01 подготовка инфраструктурных сревисов kubernetes
все конфигурационные файлы лежат в папке kuber-infra и все разложено по папкам
### 01.01 установка gitea
в папке gitea лежат конфигурационные файлы для деплоя gitea в кластер кубернетеса
#### за основу взята документация с оффициального сайта

#### 01.02 установка jenkins
в папке jenkins лежат конфигурационные файлы для деплоя jenkins кластер кубернетеса
#### за основу взята документация с оффициального сайта
на вольюме посте старта jenkins будет лежать файл с первоначальным пароле (после установки придется в консоли потыкать мышкой донастроить)

#### 01.03 установка nexus
в папке nexus  лежат конфигурационные файлы для деплоя nexus кластер кубернетеса
#### лежат конфигурационные файлы для деплоя jenkins кластер кубернетеса
на вольюме посте старта nexus будет лежать файл с первоначальным пароле (после установки придется в консоли потыкать мышкой донастроить)