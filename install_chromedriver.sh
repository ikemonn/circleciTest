#!/bin/sh

version=$(curl -s http://chromedriver.storage.googleapis.com/LATEST_RELEASE)
echo $version
if [[ "$version" =~ ^[0-9]+\.[0-9].*$ ]]; then
   echo "chromedriver version is " $version
else
   echo "Invalid chromedriver version!! Get latest version may be failed. Fix it." $version
   exit 1
fi
wget https://chromedriver.storage.googleapis.com/${version}/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
