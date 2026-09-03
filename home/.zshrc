# If you come from bash you might have to change your $PATH.
export PATH=$HOME/.config/bin:$HOME/.local/bin:/snap/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:$HOME/.local/share/nvim/mason/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export DEFAULT_USER=$USER

export GIT_EDITOR=nvim

export TERM=xterm-256color tmux

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  z
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG="en_US.utf8"
# export LC_ALL=en_EN.UTF-8
# export LANGUAGE="en_US:"
#
# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
# export ZSH_ENV_HOME=$HOME
export XDG_CONFIG_HOME=$HOME/.config

# If wsl
if [[ $(grep -i Microsoft /proc/version) ]]; then
  export BROWSER=wslview
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="nvim ~/.zshrc"
alias ohmyzsh="nvim ~/.oh-my-zsh"
alias fd="fdfind"
# Generated theme layered over the versioned config. LG_CONFIG_FILE takes a
# comma-separated list and later files win, so the repo keeps all the real
# settings and only colours are generated.
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,${XDG_STATE_HOME:-$HOME/.local/state}/theme/lazygit.yml"
alias lg="lazygit"
alias cat="bat --theme=\"base16\""
alias vim="nvim"

source "$HOME/.cargo/env"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Colours come from the generated file, which fzf re-reads on EVERY
# invocation - so a running shell picks up a new palette with no restart.
# Non-colour options stay in the env var, so a missing file degrades to
# fzf's defaults rather than to broken.
export FZF_DEFAULT_OPTS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/theme/fzf.opts"
export FZF_DEFAULT_OPTS="--height=60% --layout=reverse --border=rounded --info=inline"

. "$HOME/.asdf/asdf.sh"

# Generated highlight styles. New shells only - ZSH_HIGHLIGHT_STYLES is a
# shell-local array, so open shells keep the old palette until they exit.
_mg_zsh_hl="${XDG_STATE_HOME:-$HOME/.local/state}/theme/zsh-syntax-highlighting.zsh"
[[ -r $_mg_zsh_hl ]] && source $_mg_zsh_hl
unset _mg_zsh_hl

# bun completions
[ -s "/home/marcusg/.bun/_bun" ] && source "/home/marcusg/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# sst
export PATH=/home/marcusg/.sst/bin:$PATH

# opencode
export PATH=/home/marcusg/.opencode/bin:$PATH
export PATH="/home/marcusg/.pixi/bin:$PATH"


# Machine-local secrets (gitignored; see zsh/secrets.zsh.example).
[[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/secrets.zsh ]] \
  && source ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/secrets.zsh


# Generated config, read fresh on every prompt - so a retheme shows up on
# the next prompt in every open shell. Falls back to the default config
# path if the file is absent.
_mg_star="${XDG_STATE_HOME:-$HOME/.local/state}/theme/starship.toml"
[[ -r $_mg_star ]] && export STARSHIP_CONFIG="$_mg_star"
unset _mg_star
eval "$(starship init zsh)"
