#!/bin/bash


filename=`basename "$0"`
filename="${filename%.*}"

cp -r template $filename


sed -ir "s/YOUR_LIBRARY_NAME/libapplication_`echo $filename`/g" "$filename/Makefile.am"
sed -ir "s/YOUR_LIBRARY_SOURCES/\.\.\/`echo $filename`\.c/g" "$filename/Makefile.am"

#sed -ir 's/YOUR_LIBRARY_SOURCES/$filename' "$filename/Makefile.am"
#sed -ir 's/YOUR_LIBRARY_SOURCES/..\/$filename.c' "$filename/Makefile.am"

export PATH=$PATH:/usr/local/wsnet-2.0/bin
export WSNET_MODDIR=/home/aghiles/Aghiles/Program/xsimulation/wsnet/lib

cd $filename

./bootstrap
./configure --prefix=/home/aghiles/Aghiles/Program/xsimulation/wsnet --with-wsnet-dir=/usr/local/wsnet-2.0
make 
make install

cd ..
wsnet -c $filename.xml





