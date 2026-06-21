#!/usr/bin/env bash
set -euo pipefail

backup_dir="${1:-$HOME/minecraft-backups}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "$backup_dir"
sudo docker exec minecraft rcon-cli save-off
sudo docker exec minecraft rcon-cli save-all flush
sudo tar -C /opt/minecraft -czf "$backup_dir/minecraft-$timestamp.tar.gz" data
sudo docker exec minecraft rcon-cli save-on

echo "Backup created: $backup_dir/minecraft-$timestamp.tar.gz"

