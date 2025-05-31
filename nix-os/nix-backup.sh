#!/bin/bash

BACKUP_DIR="$HOME/nix-backup"
mkdir -p "$BACKUP_DIR"

backup() {
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    DEST="$BACKUP_DIR/backup_$TIMESTAMP"
    ARCHIVE="$BACKUP_DIR/nix_backup_$TIMESTAMP.tar.gz"

    mkdir -p "$DEST/user-config"
    mkdir -p "$DEST/system-config"

    if [ -d "$HOME/.config/nixpkgs" ]; then
        cp -r "$HOME/.config/nixpkgs" "$DEST/user-config/"
    elif [ -d "$HOME/.nixpkgs" ]; then
        cp -r "$HOME/.nixpkgs" "$DEST/user-config/"
    fi

    nix-env --query --installed --no-name > "$DEST/user-config/user-nix-packages.txt"

    tar -czf "$ARCHIVE" -C "$DEST" .
    rm -rf "$DEST"

    echo "Backup complete: $ARCHIVE"
}

restore() {
    BACKUP_TAR="$1"
    if [ -z "$BACKUP_TAR" ]; then
        echo "Usage: $0 restore /path/to/backup.tar.gz"
        exit 1
    fi

    TMP_DIR=$(mktemp -d)
    tar -xzf "$BACKUP_TAR" -C "$TMP_DIR"

    if [ -d "$TMP_DIR/user-config/nixpkgs" ]; then
        mkdir -p "$HOME/.config"
        cp -r "$TMP_DIR/user-config/nixpkgs" "$HOME/.config/"
    elif [ -d "$TMP_DIR/user-config/.nixpkgs" ]; then
        cp -r "$TMP_DIR/user-config/.nixpkgs" "$HOME/"
    fi

    if [ -f "$TMP_DIR/user-config/user-nix-packages.txt" ]; then
        xargs -a "$TMP_DIR/user-config/user-nix-packages.txt" nix-env -iA nixpkgs
    fi

    if [ -d "$TMP_DIR/system-config" ]; then
        sudo cp -r "$TMP_DIR/system-config/"* /etc/nixos/
    fi

    rm -rf "$TMP_DIR"

    echo "Restore complete. You may want to run: sudo nixos-rebuild switch"
}

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