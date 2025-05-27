#!/usr/bin/env bash
# Install curl and add-apt-repository if not already present
sudo apt update
sudo apt install curl software-properties-common -y

sudo apt install python3.11-venv -y
# Add the deadsnakes PPA
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update

# Install Python 3.11
sudo apt install python3.11 -y

# Optionally, install pip for Python 3.11
curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.11
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env 
    #source $HOME/.local/bin/env.fish (fish)

pip install --user git+https://github.com/cjbassi/rofi-copyq
