lsusb 
cd sdn-wise-contiki/sdn-wise
./RUNME.sh 
lsusb 
TARGET="z1"
sudo TARGET=$TARGET DEFINE=SINK=1
sudo make TARGET=$TARGET DEFINE=SINK=1
TARGET="z1"cd
cd
./bootstrap.sh 
./bootstrap.sh 
./sdn-wise.sh 
cd sdn-wise-contiki/sdn-wise
TARGET="z1"
sudo make TARGET=$TARGET DEFINE=SINK=1
lsusb
exit
