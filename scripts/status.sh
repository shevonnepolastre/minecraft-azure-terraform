#!/usr/bin/env bash
set -euo pipefail

sudo systemctl status minecraft --no-pager
sudo docker ps --filter name=minecraft
sudo docker logs --tail 100 minecraft

