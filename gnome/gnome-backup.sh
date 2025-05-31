#!/bin/bash

BACKUP_DIR="."
mkdir -p "$BACKUP_DIR"

backup() {
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    DEST="$BACKUP_DIR/backup_$TIMESTAMP"
    ARCHIVE="$BACKUP_DIR/gnome_backup_$TIMESTAMP.tar.gz"

    mkdir -p "$DEST"

    echo "🔄 Backing up GNOME settings..."

    dconf dump / > "$DEST/dconf-settings.ini"

    mkdir -p "$DEST/gnome-shell-extensions"
    cp -r ~/.local/share/gnome-shell/extensions/* "$DEST/gnome-shell-extensions/" 2>/dev/null

    gnome-extensions list > "$DEST/installed-extensions.txt"

    cp -r ~/.themes "$DEST/" 2>/dev/null
    cp -r ~/.icons "$DEST/" 2>/dev/null

    echo "✅ Backup complete: $ARCHIVE"
}

restore() {
    BACKUP_TAR="$1"

    if [ -z "$BACKUP_TAR" ]; then
        echo "❌ Usage: $0 restore /path/to/gnome_backup_YYYY-MM-DD_HH-MM-SS.tar.gz"
        exit 1
    fi

    if [ -f "$TMP_DIR/dconf-settings.ini" ]; then
        echo "🛠️ Restoring GNOME settings..."
        dconf load / < "$TMP_DIR/dconf-settings.ini"
    else
        echo "⚠️ No dconf-settings.ini found!"
    fi

    EXT_DIR="$TMP_DIR/gnome-shell-extensions"
    if [ -d "$EXT_DIR" ]; then
        echo "🧩 Restoring GNOME Shell extensions..."
        mkdir -p ~/.local/share/gnome-shell/extensions
        cp -r "$EXT_DIR"/* ~/.local/share/gnome-shell/extensions/

        echo "🔌 Re-enabling extensions..."
        for EXT in $(ls "$EXT_DIR"); do
            gnome-extensions enable "$EXT" || echo "⚠️ Could not enable $EXT"
        done
    fi

    [ -d "$TMP_DIR/.themes" ] && cp -r "$TMP_DIR/.themes/"* ~/.themes/
    [ -d "$TMP_DIR/.icons" ] && cp -r "$TMP_DIR/.icons/"* ~/.icons/

    echo "🧹 Cleaning up..."
    rm -rf "$TMP_DIR"

    echo "✅ Restore complete. You may need to log out and back in."
}

# === Main ===

case "$1" in
    backup)
        backup
        ;;
    restore)
        restore "$2"
        ;;
    *)
        echo "Usage: $0 backup | restore /path/to/backup.tar.gz"
        ;;
esac
