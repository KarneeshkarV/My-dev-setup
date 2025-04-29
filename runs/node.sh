#!/bin/zsh
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update

sudo apt install -y nodejs

node -v
npm -v
