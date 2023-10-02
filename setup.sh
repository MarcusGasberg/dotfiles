#!/bin/bash
set -eux
set -o pipefail

# The directory to put all the package tarballs
PACK_DIR=$HOME/packages
DOT_FILES_DIR=$HOME/.config

apt install build-essential

#######################################################################
#                            Building Tmux                            #
#######################################################################
if ! command -v tmux &> /dev/null
then

	echo "Installing tmux"
	apt install -y libevent
	apt install -y ncurses
	apt install -y tmux
else
	echo "tmux is already installed. skipping"
fi


#######################################################################
#                                 fd                                  #
#######################################################################
FD_DIR=$HOME/tools/fd

if [[ -z "$(command -v fd)" ]] && [[ ! -f "$FD_DIR/fd" ]]; then
	 apt -y install fd-find
else
    echo "fd is already installed. Skip installing it."
fi

#######################################################################
#                            Install zsh                              #
#######################################################################
if ! command -v zsh &> /dev/null
then
	echo "Installing zsh"
	apt -y install zsh	
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
	echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
fi



#######################################################################
#                             install fzf                             #
#######################################################################
if ! command -v fzf &> /dev/null
then
	apt install fzf
fi


#######################################################################
#                             install nvim                            #
#######################################################################
if ! command -v nvim &> /dev/null
then
	add-apt-repository ppa:neovim-ppa/unstable
	apt-get update
	apt-get install neovim
fi

#######################################################################
#                             install npm                             #
#######################################################################
if  [ ! -d "${HOME}/.nvm/.git" ]
then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  bash $HOME/.nvm/nvm.sh install lts/*
fi

#######################################################################
#                         install lazygit                             #
#######################################################################
if ! command -v lazygit &> /dev/null
then
  mkdir .tmp
  mkdir /root/.config

  cd .tmp
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  cd $DOT_FILES_DIR
  sudo rm -r -f .tmp
fi

#######################################################################
#                         install cargo                               #
#######################################################################
if [ ! -d "${HOME}/.cargo" ]
then
  cd $HOME
  curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
  source $HOME/.cargo/env
  cd $DOT_FILES_DIR
fi

#######################################################################
#                         install ripgrep                             #
#######################################################################
if ! command -v rg &> /dev/null
then
  ~/.cargo/bin/cargo install ripgrep 
fi


#######################################################################
#                         install delta                               #
#######################################################################
if ! command -v delta &> /dev/null
then
  ~/.cargo/bin/cargo install git-delta 
fi


ln -sf  "$DOT_FILES_DIR/.bash_profile" "$HOME/.bash_profile"
touch ~/.zshrc
ln -sf  "$DOT_FILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf  "$DOT_FILES_DIR/nvim" "$HOME/nvim"
ln -sf  "$DOT_FILES_DIR/.gitconfig" "$HOME/.gitconfig"
ln -sf  "$DOT_FILES_DIR/tmux/tmux.conf" "$HOME/tmux/tmux.conf"
ln -sf "$DOT_FILES_DIR/.git-templates" "$HOME/.git-templates"
