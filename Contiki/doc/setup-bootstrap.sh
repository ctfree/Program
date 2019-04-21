#!/bin/bash

sudo apt-get update

sudo apt-get install git curl graphviz unzip wget zip build-essential automake gettext automake software-properties-common lib32z1 lib32ncurses5 gcc-arm-none-eabi gdb-arm-none-eabi gcc gcc-msp430 libc6-i386 net-tools gcc-arm-none-eabi w3m w3m-img
sudo apt-get -o Dpkg::Options::="--force-overwrite" install gdb-arm-none-eabi

#sudo apt-get install linux-image-extra-virtual
#sudo modprobe usbserial
#sudo dmesg
#lsusb

sudo apt-get install python-pip
sudo pip install --upgrade pip
sudo pip install paho-mqtt
sudo python -m pip install pyserial
sudo python -m pip install networkx

#Aller dans /contiki/tools/cc2538-bsl
#Faire git clone https://github.com/JelmerT/cc2538-bsl.git
#Faire sudo mv cc2538-bsl/* .
#Faire rm -rf cc2538-bsl
#Aller dans /contiki/examples/hello-world
#Faire sudo apt-get install python-serial
#Faire sudo make hello-world.upload TARGET=zoul


#ssh vagrant@127.0.0.1 -p 2222 -i /path/to/private/key/vagrant -vvv
