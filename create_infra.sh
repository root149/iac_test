rm -f status
bash cd kuber
./make_kuber.sh
cd ..
cd kuber-infra
bash ./make_infra.sh
cd ..
cd kuber-mon
bash ./make_mon.sh
cd ..

