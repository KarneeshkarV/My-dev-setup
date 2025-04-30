
#!/usr/bin/env zsh
sudo apt-get update
sudo apt-get install ./docker-desktop-amd64.deb
systemctl --user start docker-desktop
