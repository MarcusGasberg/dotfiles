#!/usr/bin/bash
set -eux
set -o pipefail

# The directory to put all the package tarballs
PACK_DIR=$HOME/packages
DOT_FILES_DIR=$HOME/.config

sudo apt install build-essential

#######################################################################
#                            Building Tmux                            #
#######################################################################
if ! command -v tmux &> /dev/null
then

	echo "Installing tmux"
	sudo apt install -y libevent
	sudo apt install -y ncurses
	sudo apt install -y tmux
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
	echo "tmux is already installed. skipping"
fi

# If wsl
if [[ $(grep -i Microsoft /proc/version) ]]; then
  sudo add-apt-repository ppa:wslutilities/wslu
  sudo apt update
  sudo apt install wslu
fi


#######################################################################
#                                 fd                                  #
#######################################################################
FD_DIR=$HOME/tools/fd

if [[ -z "$(command -v fd)" ]] && [[ ! -f "$FD_DIR/fd" ]]; then
	 sudo apt -y install fd-find
else
    echo "fd is already installed. Skip installing it."
fi

#######################################################################
#                            Install zsh                              #
#######################################################################
if ! command -v zsh &> /dev/null
then
	echo "Installing zsh"
	sudo apt -y install zsh	
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
fi



#######################################################################
#                             install fzf                             #
#######################################################################
if ! command -v fzf &> /dev/null
then
	sudo apt install fzf
fi


#######################################################################
#                             install nvim                            #
#######################################################################
if ! command -v nvim &> /dev/null
then
	sudo apt-add-repository ppa:neovim-ppa/unstable
	sudo apt-get update
	sudo apt-get install neovim
fi

#######################################################################
#                             install npm                             #
#######################################################################
if  [ ! -d "${HOME}/.nvm/.git" ]
then
  cd $HOME
  sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  export NVM_DIR="$DOT_FILES_DIR/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm install node
  cd $DOT_FILES_DIR
fi

#######################################################################
#                         install lazygit                             #
#######################################################################
if ! command -v lazygit &> /dev/null
then
  sudo mkdir .tmp
  sudo mkdir /root/.config

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

#######################################################################
#                         install asdf                                #
#######################################################################
if ! command -v asdf &> /dev/null
then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
fi


sudo ln -sf  "$DOT_FILES_DIR/.bash_profile" "$HOME/.bash_profile"
touch ~/.zshrc
if [ ! -d "/root/tmux" ] 
then
sudo mkdir /root/tmux
fi	
sudo ln -sf  "$DOT_FILES_DIR/tmux/tmux.conf" "$HOME/tmux/tmux.conf"
sudo ln -sf  "$DOT_FILES_DIR/.zshrc" "$HOME/.zshrc"
sudo ln -sf  "$DOT_FILES_DIR/nvim" "$HOME/nvim"
sudo ln -sf  "$DOT_FILES_DIR/.gitconfig" "$HOME/.gitconfig"
sudo ln -sf "$DOT_FILES_DIR/.git-templates" "$HOME/.git-templates"
sudo ln -sf  "$DOT_FILES_DIR/.config/nvim/lua/plugins/snippets" "$HOME/snippets"
