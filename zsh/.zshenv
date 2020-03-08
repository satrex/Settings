#[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm


## load user .zshrc configuration file
#
alias rake="noglob rake"
# PATH=/opt/bitnami/ruby/bin/:${PATH}
export RUBYLIB=.:$RUBYLIB

#=============================
## rbenv
##=============================

# rbenvの設定：パスが見つからないため、いったんおやすみ

#if [ -d ${HOME}/.rbenv ] ; then
#PATH=${HOME}/.rbenv/shims:/usr/local/packer:${PATH}
#export PATH
#eval "$(rbenv init -)"
#fi

# alias brew="env PATH=${PATH/\/Library\/Frameworks\/Python\.framework\/Versions/3\.6/bin:/} brew"
