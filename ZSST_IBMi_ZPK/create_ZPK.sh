#!/bin/bash

TS=$(date +%y%m%d.%H%M%S)

sed -i '' "s|^\(.*<release>9\.1\.\).*\(</release>\)|\1$TS\2|" deployment.xml

zip -r -9 ZSST_IBMi_9.1.${TS}.zpk data scripts read.txt ZSST_icon.png deployment.xml
