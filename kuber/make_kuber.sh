git clone https://github.com/kubernetes-sigs/kubespray.git
echo git clone $(date) >>../status

ln -s $(pwd)/homelab/ $(pwd)/kubespray/inventory/homelab
cd kubespray
pip install -r requirements.txt
ansible-playbook -i ./inventory/homelab/inventory.ini --become --become-user=root cluster.yml
mkdir -p ~/.kube
cd ..
echo kubespray $(date) >>../status
ln -s $(pwd)/homelab/artifacts/admin.conf ~/.kube/config

cd ingress
bash ./make_insgress.sh
cd ..
echo ingress $(date) >>../status

cd dashboard
bash ./make_dashboard.sh
cd ..
echo dashboard $(date) >>../status

cd csi
bash ./make_csi.sh
cd ..
echo csi $(date) >>../status
