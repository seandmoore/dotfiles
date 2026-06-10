# Shell history + fzf history menu (managed by dotfiles)

# Bigger, deduplicated, shared history
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups   # skip dupes and space-prefixed commands
shopt -s histappend                # append instead of overwrite on exit
# Flush each command to the history file immediately so new shells see it
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# fzf: Ctrl+R opens a fuzzy-searchable menu of past commands,
# Ctrl+T inserts a file path, Alt+C cd's into a directory
if [[ -f /usr/share/fzf/key-bindings.bash ]]; then
  . /usr/share/fzf/key-bindings.bash
  . /usr/share/fzf/completion.bash
  export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border --info=inline"
  export FZF_CTRL_R_OPTS="--prompt='history ❯ ' --preview='echo {}' --preview-window=down:3:wrap"
fi

# atuin: richer history menu (exit codes, durations, per-dir filters) takes over
# Ctrl+R; fzf keeps Ctrl+T / Alt+C. Up-arrow stays plain bash. Must come after
# the fzf block so atuin wins the Ctrl+R binding; falls back to fzf if absent.
if command -v atuin &>/dev/null; then
  [[ -f /usr/share/bash-preexec/bash-preexec.sh ]] && . /usr/share/bash-preexec/bash-preexec.sh
  eval "$(atuin init bash --disable-up-arrow)"
fi
