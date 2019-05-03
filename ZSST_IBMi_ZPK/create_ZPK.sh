#!/bin/bash

TS=$(date +%y%m%d.%H%M%S)

mv deployment.xml deployment.xml.BAK
sed "s|^\(.*<release>2018\.0\.\).*\(</release>\)|\1$TS\2|" deployment.xml.BAK > deployment.xml

zip -r -9 ZSST_IBMi_2018.0.${TS}.zpk data scripts read.txt ZSST_icon.png deployment.xml
rm -f deployment.xml
mv deployment.xml.BAK deployment.xml
