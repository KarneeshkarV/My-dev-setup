#!/usr/bin/env zsh
sudo rm -rf /usr/local/go
wget https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz
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
go install github.com/jesseduffield/lazygit@latest
