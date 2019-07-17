exit
ls
cd A8/
ls
cd /
ls
cd home/
ls
cd senslabeh/
ls
whereis 18
whereis A8
find A8
cd /
whereis A8
cd ~
ls
pwd
cd /
ls
cd senslab/
ls
cd users/
ls
cd aabdulla/
cd 
cd ~
cd .senslab/
ls
ls -h
ls -hl
ls -A
ls -a
cd ..
ls
cd /
ls
cd ~
ls
pwd
ls
cd iot-lab/
ls
ls -A
cd parts/
ls -A
ls
cd openlab/
ls
cd ..
ls
nc m3-5 20000 
nc m3-1.saclay.iot-lab.info 20000 
git clone https://github.com/iot-lab/iot-lab.git
cd iot-lab
make
make setup-contiki
make setup-riot 
cd ~/iot-lab/parts/contiki/examples/iotlab/03-sensors-collecting
make TARGET=iotlab-m3
make TARGET=iotlab-a8-m3
iotlab-experiment submit -n contiki -d 15 -l 1,archi=m3:at86rf231+site=grenoble+mobile=0,sensors-collecting.iotlab-m3
iotlab-auth
iotlab-auth djoudi
iotlab-auth -u djoudi
iotlab-auth -udjoudi
iotlab-experiment submit -n contiki -d 15 -l 1,archi=m3:at86rf231+site=grenoble+mobile=0,sensors-collecting.iotlab-m3
nc m3-1 20000
cd ~/iot-lab/parts/contiki/examples/ipv6/rpl-border-router
make TARGET=iotlab-m3
cp border-router.iotlab-m3 ~/
cd ~/iot-lab/parts/contiki/examples/iotlab/04-er-rest-example
make TARGET=iotlab-m3
cp er-example-server.iotlab-m3 ~/
cd
sudo tunslip6.py -v2 -L -a m3-1 -p 20000 2001:660:5307:3100::1/64
echo $PATH
ls
ssh root@node-m3-100.grenoble.iot-lab.info
experiment-cli get -r
ssh root@node-m3-100.grenoble.iot-lab.info
sudo ssh root@node-m3-100.grenoble.iot-lab.info
cd A8/
ssh root@node-m3-100.grenoble.iot-lab.info
ssh root@node-m3-96.grenoble.iot-lab.info
ssh root@m3-96.grenoble.iot-lab.info
cd ~/iot-lab/parts/contiki/examples/ipv6/rpl-border-router
gedit
vi 
vim
vim project-conf.h 
cd ~/iot-lab/parts/contiki/examples/ipv6/rpl-border-router
vim project-conf.h 
coap get coap://[2001:660:5307:3100::9982]:5683/.well-known/core
ip -6 route
iotlab-node --update ~/iot-lab/parts/contiki/examples/ipv6/rpl-border-router/border-router.iotlab-m3 -l grenoble,m3,1
iotlab-node --update ~/iot-lab/parts/contiki/examples/ipv6/rpl-border-router/border-router.iotlab-m3 -l grenoble,m3,100
ping6 2001:660:5307:3100::2354
nc m3-101 20000
iotlab-node --update ~/iot-lab/parts/contiki/examples/iotlab/04-er-rest-example/er-example-server.iotlab-m3 -e grenoble,m3,100
lynx -dump http://[2001:660:5307:3100::2354]
cat tunslip6.py
cd ~/iot-lab/parts/contiki/examples/ipv6/rpl-border-router
vim project-conf.h 
make TARGET=iotlab-m3
vim project-conf.h 
make TARGET=iotlab-m3
cp border-router.iotlab-m3 ~/
cd ~/iot-lab/parts/contiki/examples/iotlab/04-er-rest-example
vim project-conf.h 
make TARGET=iotlab-m3
vim project-conf.h 
cp er-example-server.iotlab-m3 ~/
sudo tunslip6.py -v2 -L -a m3-1 -p 20000 2001:660:5307:3100::1/64
experiment-cli get -r
iotlab-experiment get -r
iotlab-experiment get -i
ls
cd
sudo tunslip6.py -v2 -L -a m3-1 -p 20000 2001:660:5307:3100::1/64
iotlab-experiment submit -n contiki -d 5 -l 1,archi=m3:at86rf231+site=grenoble+mobile=0,sensors-collecting.iotlab-m3submi
sudo tunslip6.py -v2 -L -a m3-100 -p 20000 2001:660:5307:3100::1/64
cd ~/.iot-lab/
ls
cd last
ls
cd consumption/
ls
ll
ls
cd ../radio/
ls
cd ../..
ls
cd 174579/
ls
ls -a
ls ~/.iot-lab/last/consumption/
ls
ls ~/.iot-lab/last/consumption/
plot_oml_consum
ls -a
gedit .bash
gedit .bashrc 
cat .bashrc 
la
ls -a
cat .iotlabrc 
cd iot-lab/
ls
cd ..
cd .senslab/
ls
ls last/consumption/
exit
less ~/.iot-lab/last/radio/m3-100.oml
lss ~/.iot-lab/last/radio/m3_100.oml 
les ~/.iot-lab/last/radio/m3_100.oml 
less ~/.iot-lab/last/radio/m3_100.oml 
plot_oml_radio -a -i ~/.iot-lab/last/radio/m3_100.oml
cd iot-lab/parts/openlab/
cd appli/iotlab_examples/tutorial 
vim main.c 
make tutorial_m3
ls
cd ~/iot-lab/parts/openlab/build.m
cd ~/iot-lab/parts/openlab/
whereis build
finf build
find build
cd ../..
whereis tutorial_m3
find tutorial_m3
tree
cd
ls
iotlab-experiment -r
iotlab-experiment get
iotlab-experiment get -r
nc m3-100 20000 
nc m3-101 20000 
ls
ls -l
cd iot-lab/
ls
ls -a
cd .iot-lab
ls
cd
ls
cd ..
ls
