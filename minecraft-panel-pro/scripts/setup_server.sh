#!/data/data/com.termux/files/usr/bin/bash

pkg update -y
pkg install -y openjdk-21 wget curl jq git nano

mkdir -p ~/minecraft-server/plugins

echo "eula=true" > ~/minecraft-server/eula.txt

echo "✅ Dependencies installed!"
