#!/data/data/com.termux/files/usr/bin/bash

clear
echo "🔥 Installing Minecraft Panel Pro..."

mkdir -p ~/minecraft-server

cp menu.sh ~/minecraft-server/menu.sh
chmod +x ~/minecraft-server/menu.sh

cat > $PREFIX/bin/mc << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~/minecraft-server
./menu.sh "$@"
EOF

chmod +x $PREFIX/bin/mc

echo "✅ Installed! Use: mc -s setup"
