#!/usr/bin/env zsh 

setopt promptsubst

autoload -U add-zsh-hook
BLUE=$FG[111]
ORANGE=$FG[208]
PURPLE=$FG[103]
RED=$FG[124]
GREEN=$FG[148]
GRAY=$FG[240]
WHITE=$FG[255]
YELLOW=$FG[220]

#%{$BLUE%}%B┌──%b%{$reset_color%} %{$ORANGE%}%B%n%b%{$reset_color%}%{$WHITE%} %B@%b %{$reset_color%}%{$YELLOW%}%m%b %{$reset_color%}%{$PURPLE%}%B%~%b%{$reset_color%} %{$GREEN%}%B$(git_prompt_info)$(hg_prompt_info)%b%{$RED%}%B%b %{$reset_color%}
PROMPT='
%{$GRAY%}%U${(r:$COLUMNS:: :)}%u%{$reset_color%}

%{$BLUE%}%B┌── %{$reset_color%}%{$PURPLE%}%B%~%b%{$reset_color%} %{$GREEN%}%B$(git_prompt_info)$(hg_prompt_info)%b%{$RED%}%B%b %{$reset_color%}
%{$BLUE%}%B└─ᐅ%b %{$reset_color%} '

RPROMPT='%B[%b%{$BLUE%}%B%T%b%{$reset_color%}%B]%b'

# git
ZSH_THEME_GIT_PROMPT_PREFIX=": "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$GREEN%} : "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$RED%}✘"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$GREEN%}✔"

ZSH_THEME_GIT_PROMPT_ADDED="%{$BLUE%}✚%{$rset_color%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$BLUE%}✹%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$BLUE%}✖%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$BLUE%}➜%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$BLUE%}═%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$BLUE%}✭%{$reset_color%}"

# mercurial
ZSH_THEME_HG_PROMPT_PREFIX=$ZSH_THEME_GIT_PROMPT_PREFIX
ZSH_THEME_HG_PROMPT_SUFFIX=$ZSH_THEME_GIT_PROMPT_SUFFIX
ZSH_THEME_HG_PROMPT_DIRTY=$ZSH_THEME_GIT_PROMPT_DIRTY
ZSH_THEME_HG_PROMPT_CLEAN=$ZSH_THEME_GIT_PROMPT_CLEAN

ZSH_THEME_HG_PROMPT_ADDED=$ZSH_THEME_GIT_PROMPT_ADDED
ZSH_THEME_HG_PROMPT_MODIFIED=$ZSH_THEME_GIT_PROMPT_MODIFIED
ZSH_THEME_HG_PROMPT_DELETED=$ZSH_THEME_GIT_PROMPT_DELETED
ZSH_THEME_HG_PROMPT_RENAMED=$ZSH_THEME_GIT_PROMPT_RENAMED
ZSH_THEME_HG_PROMPT_UNMERGED=$ZSH_THEME_GIT_PROMPT_UNMERGED
ZSH_THEME_HG_PROMPT_UNTRACKED=$ZSH_THEME_GIT_PROMPT_UNTRACKED

# See http://geoff.greer.fm/lscolors/
#export LSCOLORS="exfxcxdxbxbxbxbxbxbxbx"
#export LS_COLORS="di=35;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=31;40:cd=31;40:su=31;40:sg=31;40:tw=31;40:ow=31;40:"
export LSCOLORS="cxfxcxdxbxegedabagacad"
export LS_COLORS="di=32:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"

