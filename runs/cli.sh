#!/usr/bin/env bash 
sudo apt install copyq bat xclip xdotool maim zoxide rofi gcc g++ cmake make ninja-build gdb doxygen -y
sudo apt-get install pulseaudio pavucontrol -y && pavucontrol 
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
 ~/.fzf/install
 fzf --version
