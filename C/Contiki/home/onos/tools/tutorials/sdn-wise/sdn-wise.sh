#!/bin/bash

USER="user"

# Let's free up some space
rm -Rf ~/contiki-3.0
rm -Rf ~/contiki
apt-get remove --purge libreoffice* openjdk-* thunderbird -y
apt-get clean
apt-get autoremove -y

# Update to Java 8 and install Ant and Maven
add-apt-repository ppa:openjdk-r/ppa -y
apt-get update
apt-get install net-tools openjdk-8-jdk ant maven git curl openvswitch-switch -y
update-java-alternatives -s java-1.8.0-openjdk-i386

# Setup environment variables
sudo -u $USER sed -i '/export JAVA_HOME=\/usr\/lib\/jvm\/java-7-openjdk-i386/c\export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-i386' ~/.bashrc
source ~/.bashrc

# Download sdn-wise-contiki
sudo -u $USER git clone git://github.com/sdnwiselab/sdn-wise-contiki

# Download ONOS
sudo -u $USER git clone git://github.com/sdnwiselab/onos
sudo -u $USER git checkout onos-sdn-wise-1.0

# Download Mininet
sudo -u $USER git clone git://github.com/mininet/mininet

# Setup environment variables
sudo -u $USER echo "export ONOS_ROOT=~/onos" >> ~/.bashrc
source ~/.bashrc
source $ONOS_ROOT/tools/dev/bash_profile

# Install Mininet
mininet/util/install.sh -nfv

# Download sdn-wise subprojects
cd sdn-wise-contiki && sudo -u $USER git submodule update --init && cd contiki/tools/cooja && sudo -u $USER git submodule update --init && cd
