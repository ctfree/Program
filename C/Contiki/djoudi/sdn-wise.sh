#!/bin/bash

USER="vagrant"

# Let's free up some space
#sudo apt-get remove --purge libreoffice* openjdk-* firefox thunderbird -y
#sudo apt-get clean
#sudo apt-get autoremove -y

# Update to Java 8 and install Ant and Maven
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt-get update
sudo apt-get install openjdk-8-jdk ant maven openvswitch-switch -y
sudo update-java-alternatives --jre-headless --jre --set java-1.8.0-openjdk-amd64
#sudo update-alternatives --config java

# Setup environment variables
#sed -i '/export JAVA_HOME=\/usr\/lib\/jvm\/java-7-openjdk-i386/c\export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' ~/.bashrc
#source ~/.bashrc

#git clone git://github.com/millionb/sdn-wise-contiki
git clone git://github.com/sdnwiselab/sdn-wise-java
git clone git://github.com/sdnwiselab/onos
git clone git://github.com/mininet/mininet
# Downlad Apache Karaf
mkdir Downloads Applications
wget http://archive.apache.org/dist/karaf/3.0.2/apache-karaf-3.0.2.tar.gz -P Downloads
tar -zxvf Downloads/apache-karaf-3.0.2.tar.gz -C Applications/
# Download sdn-wise subprojects
cd sdn-wise-contiki && git submodule update --init
cd contiki/tools/cooja && git submodule update --init && cd

# Add ONOS and SDN-WISE to Karaf
sudo sed -i '/featuresRepositories=mvn:org.apache.karaf.features\/standard\/3.0.2\/xml\/features,mvn:org.apache.karaf.features\/enterprise\/3.0.2\/xml\/features,mvn:org.ops4j.pax.web\/pax-web-features\/3.1.2\/xml\/features,mvn:org.apache.karaf.features\/spring\/3.0.2\/xml\/features/c\featuresRepositories=mvn:org.apache.karaf.features\/standard\/3.0.2\/xml\/features,mvn:org.apache.karaf.features\/enterprise\/3.0.2\/xml\/features,mvn:org.ops4j.pax.web\/pax-web-features\/3.1.2\/xml\/features,mvn:org.apache.karaf.features\/spring\/3.0.2\/xml\/features,mvn:org.onosproject\/onos-features\/1.0.2-SNAPSHOT\/xml\/features' Applications/apache-karaf-3.0.2/etc/org.apache.karaf.features.cfg
sudo sed -i '/featuresBoot=config,standard,region,package,kar,ssh,management/c\featuresBoot=config,standard,region,package,kar,ssh,management,onos-api,onos-core-trivial,onos-cli,onos-openflow,onos-app-fwd,onos-app-mobility,onos-gui,onos-sdnwise,onos-sdnwise-providers' Applications/apache-karaf-3.0.2/etc/org.apache.karaf.features.cfg

# Setup environment variables
echo "export ONOS_ROOT=/home/aghiles/These/Program/C/Contiki/djoudi/onos" >> ~/.bashrc
source ~/.bashrc
source $ONOS_ROOT/tools/dev/bash_profile

# Install Mininet
mininet/util/install.sh -nfv

cd onos
tools/build/onos-buck build onos --show-output 



