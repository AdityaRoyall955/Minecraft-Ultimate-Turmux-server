#!/data/data/com.termux/files/usr/bin/bash

clear
echo "🔥 Installing Minecraft Panel Pro..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/minecraft-server"

mkdir -p "$TARGET_DIR"

echo "📂 Copying files..."
cp "$SCRIPT_DIR/menu.sh" "$TARGET_DIR/menu.sh"
chmod +x "$TARGET_DIR/menu.sh"

if [[ -d "$SCRIPT_DIR/core" ]]; then
    cp -r "$SCRIPT_DIR/core" "$TARGET_DIR/"
    echo "✅ Copied core configuration"
fi

if [[ -d "$SCRIPT_DIR/scripts" ]]; then
    cp -r "$SCRIPT_DIR/scripts" "$TARGET_DIR/"
    chmod +x "$TARGET_DIR/scripts/"*.sh 2>/dev/null
    echo "✅ Copied scripts"
fi

if [[ -d "$SCRIPT_DIR/plugins" ]]; then
    cp -r "$SCRIPT_DIR/plugins" "$TARGET_DIR/"
    chmod +x "$TARGET_DIR/plugins/"*.sh 2>/dev/null
    echo "✅ Copied plugins"
fi

if [[ -d "$SCRIPT_DIR/docs" ]]; then
    cp -r "$SCRIPT_DIR/docs" "$TARGET_DIR/"
    echo "✅ Copied documentation"
fi

cat > "$PREFIX/bin/mc" << EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "$TARGET_DIR" || exit 1
./menu.sh "\$@"
EOF

chmod +x "$PREFIX/bin/mc"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Usage:"
echo "  mc -s setup    - Install dependencies"
echo "  mc -s start    - Start server"
echo "  mc -s restart  - Restart server"
echo "  mc -s stop     - Stop server"
echo "  mc -s plugins  - Download plugins"
echo "  mc -s status   - Check server status"
echo ""
echo "Config file: $TARGET_DIR/core/server.conf"
