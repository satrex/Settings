# users generic .zshrc file for zsh(1)
## Environment variable configuration
#
# LANG
#
export LANG=ja_JP.UTF-8
## Default shell configuration
#
# set prompt
#

export TERM=xterm-256color
autoload colors
colors
#case ${UID} in
#0)
#  PROMPT="%B%{${fg[red]}%}%/#%{${reset_color}%}%b "
#  PROMPT2="%B%{${fg[red]}%}%_#%{${reset_color}%}%b "
#  SPROMPT="%B%{${fg[red]}%}%r is correct? [n,y,a,e]:%{${reset_color}%}%b "
 # [ -n "${REMOTEHOST}${SSH_CONNECTION}" ] &&
  #  PROMPT="%{${fg[white]}%}${HOST%%.*} ${PROMPT}"
 # ;;
#*)
#  PROMPT="%{${fg[red]}%}%/%%%{${reset_color}%} "
#  PROMPT2="%{${fg[red]}%}%_%%%{${reset_color}%} "
#  SPROMPT="%{${fg[red]}%}%r is correct? [n,y,a,e]:%{${reset_color}%} "
#  [ -n "${REMOTEHOST}${SSH_CONNECTION}" ] &&
#    PROMPT="%{${fg[white]}%}${HOST%%.*} ${PROMPT}"
#  ;;
#esac

PROMPT="
 %{${fg[red]}%}%~%{${reset_color}%} 
 [%n]$ "
# auto change directory
#
setopt auto_cd
# auto directory pushd that you can get dirs list by cd -[tab]
#
setopt auto_pushd
# command correct edition before each completion attempt
#
setopt correct
# compacked complete list display
#
setopt list_packed
# no remove postfix slash of command line
#
setopt noautoremoveslash
# no beep sound when complete list displayed
#
setopt nolistbeep
## Keybind configuration
#
# emacs like keybind (e.x. Ctrl-a goes to head of a line and Ctrl-e goes
# to end of it)
#
bindkey -e
# historical backward/forward search with linehead string binded to ^P/^N
#
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end
bindkey "\\ep" history-beginning-search-backward-end
bindkey "\\en" history-beginning-search-forward-end
## Command history configuration
#
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt hist_ignore_dups # ignore duplication command history list
setopt share_history # share command history data
## Completion configuration
#
autoload -U compinit
compinit
## Alias configuration
#
# expand aliases before completing
#
setopt complete_aliases # aliased ls needs if file/dir completions work
alias where="command -v"
alias j="jobs -l"
case "${OSTYPE}" in
freebsd*|darwin*)
  alias ls="ls -G -w"
  ;;
linux*)
  alias ls="ls --color"
  ;;
esac
alias la="ls -a"
alias lf="ls -F"
alias ll="ls -l"
alias du="du -h"
alias df="df -h"
alias su="su -l"
alias vi-="vim"

## terminal configuration
#
unset LSCOLORS
case "${TERM}" in
xterm)
  export TERM=xterm-color
  ;;
kterm)
  export TERM=kterm-color
  # set BackSpace control character
  stty erase
  ;;
cons25)
  unset LANG
  export LSCOLORS=ExFxCxdxBxegedabagacad
  export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
  zstyle ':completion:*' list-colors \
    'di=;34;1' 'ln=;35;1' 'so=;32;1' 'ex=31;1' 'bd=46;34' 'cd=43;34'
  ;;
esac
# set terminal title including current directory
#
case "${TERM}" in
kterm*|xterm*)
  precmd() {
    echo -ne "\033]0;${USER}@${HOST%%.*}:${PWD}\007"
  }
  export LSCOLORS=exfxcxdxbxegedabagacad
  export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
  zstyle ':completion:*' list-colors \
    'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'
  ;;
esac
## load user .zshrc configuration file
#
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine

setopt nullglob
setopt extended_history
function history-all { history -E 1 }

# RUBY
export PATH="/opt/bitnami/ruby/bin:/usr/local/packer:$PATH"
alias brake="bundle exec rake"
export RUBYLIB=.:$RUBYLIB
export MAILCHECK=0

# RUBYENV 
#if [ -d ${HOME}/.rbenv ] ; then
#    export PATH="$HOME/.rbenv/bin:$PATH"
    #eval "$(rbenv init -)"
#    eval "$(rbenv init - zsh)"
#    export CC=/usr/bin/gcc
#fi
#export RBENV_ROOT="${HOME}/.rbenv"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return


# pyenv
#export PYENV_ROOT="${HOME}/.pyenv"
#if [ -d "${PYENV_ROOT}" ]; then
#    export PATH=${PYENV_ROOT}/bin:$PATH
#    eval "$(pyenv init -)"
#fi


test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# The next line updates PATH for the Google Cloud SDK.
source '/Users/suzukisatoshi/tool/google-cloud-sdk/path.zsh.inc'

# The next line enables shell command completion for gcloud.
source '/Users/suzukisatoshi/tool/google-cloud-sdk/completion.zsh.inc'

# コマンド入力時に、英数に自動切替
autoload -Uz add-zsh-hook

function force-alphanumeric {
  case "${OSTYPE}" in
  darwin*)
    # 「英数」キーを押す
    # 若干重いので サブシェル + バックグラウンド で実行する
    (osascript -e 'tell application "System Events" to key code {102}' &)
  esac
}

#source ~/.nvm/nvm.sh
add-zsh-hook precmd force-alphanumeric

PATH="/Users/suzukisatoshi/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/Users/suzukisatoshi/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/Users/suzukisatoshi/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/Users/suzukisatoshi/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/Users/suzukisatoshi/perl5"; export PERL_MM_OPT;

# pythonの設定
#export WORKON_HOME=$HOME/.virtualenvs
	
#export PATH="/usr/local/opt/python/libexec/bin:$PATH"
#export VIRTUALENVWRAPPER_PYTHON=/usr/local/opt/python/libexec/bin/python
#source /usr/local/bin/virtualenvwrapper.sh

# nodebrewの設定
#export PATH=$HOME/.nodebrew/current/bin:$PATH

export PATH="/usr/local/opt/libxslt/bin:$PATH"
export PATH="/usr/local/Cellar/node/12.11.1/bin:$PATH"

# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
[[ -f /Users/suzukisatoshi/.nodebrew/node/v10.7.0/lib/node_modules/electron-forge/node_modules/tabtab/.completions/electron-forge.zsh ]] && . /Users/suzukisatoshi/.nodebrew/node/v10.7.0/lib/node_modules/electron-forge/node_modules/tabtab/.completions/electron-forge.zsh
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
#export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/mysql-client/bin:$PATH"
