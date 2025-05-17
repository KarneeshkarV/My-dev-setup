#!/usr/bin/env bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update

sudo apt install -y nodejs
sudo npm install -g neovim
node -v
npm -v
