#!/usr/bin/env zsh
sudo apt install curl
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.10 -y
sudo apt install pip3
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env 
    #source $HOME/.local/bin/env.fish (fish)


