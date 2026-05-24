#!/data/data/com.termux/files/usr/bin/bash

mkdir -p plugins

wget -O plugins/Geyser-Spigot.jar \
https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot

wget -O plugins/floodgate-spigot.jar \
https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot

echo "✅ Plugins installed!"
