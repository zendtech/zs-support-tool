#!/bin/bash

PackDir=/tmp/zsst_zpk_pack_$(date +%s)
TS=$(date +%y%m%d)

mkdir $PackDir

cp deployment.xml $PackDir/d.xml
cp read.txt ZSST_icon.png $PackDir/
cp -R data scripts $PackDir/
cp ../ZSST_IBMi/bin/support_tool.sh $PackDir/data/bin/
cp -R ../ZSST_IBMi/share $PackDir/data/

pushd .
cd $PackDir

sed "s|^\(.*<release>Multi\.\).*\(</release>\)|\1$TS\2|" d.xml > deployment.xml
zip -r -9 ZSST_IBMi_Multi.${TS}.zpk data scripts read.txt ZSST_icon.png deployment.xml

popd
mv $PackDir/ZSST_IBMi_Multi.${TS}.zpk .

rm -rf $PackDir
