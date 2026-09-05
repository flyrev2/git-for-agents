#!/bin/sh
# Install git-for-agents for every tool on this machine, by adding the
# config as a global include. Safe to run repeatedly.
#
#   curl -fsSL https://raw.githubusercontent.com/flyrev2/git-for-agents/main/install.sh | sh
#   ./install.sh              # from a checkout
#   ./install.sh --uninstall
set -e

url=https://raw.githubusercontent.com/flyrev2/git-for-agents/main/gitconfig
dir=${XDG_CONFIG_HOME:-$HOME/.config}/git-for-agents
file=$dir/gitconfig

if [ "$1" = "--uninstall" ]; then
	git config --global --unset-all include.path "^$file\$" 2>/dev/null || true
	rm -f "$file"
	echo "Removed $file and its include from ~/.gitconfig"
	exit 0
fi

mkdir -p "$dir"
here=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)
if [ -n "$here" ] && [ -f "$here/gitconfig" ]; then
	cp "$here/gitconfig" "$file"
else
	curl -fsSL "$url" -o "$file"
fi

if ! git config --global --get-all include.path 2>/dev/null | grep -qx "$file"; then
	git config --global --add include.path "$file"
fi

echo "Installed $file"
echo "Included from: $(git config --global --show-origin include.path | sed -n "s|^file:\(.*\)\t.*|\1|p" | head -1)"
echo "Undo: $0 --uninstall  (or: git config --global --unset include.path $file)"
