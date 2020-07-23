export PATH="/home/linuxbrew/.linuxbrew/bin":"/usr/local/bin":${PATH}
if [[ -x "$(command -v brew)" ]]; then
  eval $(brew shellenv)
fi