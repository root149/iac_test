cd kubespray
echo yes | ansible-playbook -i ./inventory/homelab/inventory.ini --become --become-user=root reset.yml
cd ..
