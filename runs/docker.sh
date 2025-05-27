#!/usr/bin/env bash
sudo apt-get update
sudo apt-get install ./docker-desktop-amd64.deb -y
systemctl --user start docker-desktop
sudo usermod -aG docker $USER
newgrp docker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
