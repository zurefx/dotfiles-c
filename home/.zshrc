export ZSH_DISABLE_COMPFIX=true

source ~/.powerlevel10k/powerlevel10k.zsh-theme

alias cat="batcat --theme='Solarized (dark)'"
alias ls='eza --icons=always --color=always'
alias ll='eza --icons=always --color=always -la'

LS_COLORS="di=38;2;129;161;193:fi=38;2;216;222;233:ex=38;2;163;190;140:ln=38;2;208;135;112:so=38;2;235;203;139:pi=38;2;180;142;173:bd=38;2;191;97;106:cd=38;2;143;188;187:or=38;2;255;85;85:mi=38;2;255;0;0"
export LS_COLORS

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=245'
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

ASCII_DIR="$HOME/.config/ascii"
ASCII_FILE=$(find "$ASCII_DIR" -name "*.txt" | shuf -n 1)
command cat "$ASCII_FILE"

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_HIGHLIGHT_STYLES[command]='fg=111,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=147,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=183,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=218,bold'
ZSH_HIGHLIGHT_STYLES[external]='fg=117,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=213,bold'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=245'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=245'
ZSH_HIGHLIGHT_STYLES[arg]='fg=225'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=217,bold'
