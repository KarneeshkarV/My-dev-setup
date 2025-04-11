
#!/usr/bin/env bash
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.10 -y
curl -LsSf https://astral.sh/uv/install.sh | sh


