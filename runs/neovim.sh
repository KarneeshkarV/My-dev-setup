#!/usr/bin/env bash 
echo "neo";
sudo apt update
sudo apt install ripgrep git xclip cmake gettext lua5.1 liblua5.1-0-dev unzip wget 
-y

version="v0.10.2"
if [ ! -z $NVIM_VERSION ]; then
    version="$NVIM_VERSION"
fi

echo "version: \"$version\""
# neovim btw
if [ ! -d $HOME/neovim ]; then
    git clone https://github.com/neovim/neovim.git $HOME/neovim --depth 3
fi

git -C ~/neovim fetch --all
git -C ~/neovim checkout $version

make -C ~/neovim clean
make -C ~/neovim CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make -C ~/neovim install
git clone https://github.com/watninja68/karnee_neovim_config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
#git clone https://github.com/ThePrimeagen/harpoon.git $HOME/personal/harpoon
#cd $HOME/personal/harpoon
#git fetch
#git checkout harpoon2

#git clone https://github.com/ThePrimeagen/vim-apm.git $HOME/personal/vim-apm
#git clone https://github.com/ThePrimeagen/vim-with-me.git $HOME/personal/vim-with-me
#git clone https://github.com/ThePrimeagen/vim-arcade.git $HOME/personal/vim-arcade
#git clone https://github.com/ThePrimeagen/caleb.git $HOME/personal/caleb
#git clone https://github.com/nvim-lua/plenary.nvim.git $HOME/personal/plenary

wget --no-check-certificate https://luarocks.org/releases/luarocks-3.11.1.tar.gz

#curl -O https://luarocks.org/releases/luarocks-3.11.1.tar.gz
tar zxpf luarocks-3.11.1.tar.gz
cd luarocks-3.11.1
./configure && make && sudo make install
sudo luarocks install luacheck
