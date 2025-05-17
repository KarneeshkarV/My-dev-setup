#!/usr/bin/env zsh
curl -OL https://golang.org/dl/go1.16.7.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.16.7.linux-amd64.tar.gz
LINE='export PATH=$PATH:/usr/local/go/bin'

# File to modify
PROFILE="$HOME/.profile"

# Check if the line already exists
if ! grep -Fxq "$LINE" "$PROFILE"; then
    echo "$LINE" >> "$PROFILE"
    echo "Line added to $PROFILE"
else
    echo "Line already exists in $PROFILE"
fi
source ~/.profile
go version
go install github.com/danielmiessler/fabric@latest
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
