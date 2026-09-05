#!/bin/sh
# Measure Git output (stdout+stderr) for a typical agent workflow,
# with and without gitconfig. Prints a Markdown table.
#
#   ./measure.sh [git-binary]
set -e
GIT=${1:-git}
here=$(cd "$(dirname "$0")" && pwd)
cfg="$here/gitconfig"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

export GIT_AUTHOR_NAME=agent GIT_AUTHOR_EMAIL=agent@example.com
export GIT_COMMITTER_NAME=agent GIT_COMMITTER_EMAIL=agent@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=
unset GIT_CONFIG_NOSYSTEM

# Fixed scenario; each step's output is captured to $out/NN-name.
run_scenario () {
	out=$1; mkdir -p "$out"
	d="$work/repo-$(basename "$out")"; remote="$work/remote-$(basename "$out").git"
	$GIT init -q --bare -b main "$remote"
	n=0
	step () { n=$((n+1)); name=$1; shift; "$@" >"$out/$n-$name" 2>&1 || true; }
	mkdir -p "$d" && cd "$d"
	step init      $GIT init -b main
	printf 'one\n' >a.txt; printf 'x\n' >b.txt
	step add       $GIT add .
	step commit    $GIT commit -m "initial"
	step remote    $GIT remote add origin "$remote"
	step push      $GIT push -u origin main
	step checkout-b $GIT checkout -b feature
	printf 'two\n' >>a.txt
	step status    $GIT status
	step commit2   $GIT commit -am "feature work"
	step switch    $GIT switch main
	printf 'y\n' >>b.txt
	step commit3   $GIT commit -am "main work"
	step merge     $GIT merge feature
	step fetch     $GIT fetch origin
	step push2     $GIT push
	step tag       $GIT tag v1
	printf 'wip\n' >>a.txt
	step stash     $GIT stash
	step stash-pop $GIT stash pop
	step reset     $GIT reset --hard HEAD
	step log       $GIT log -3
	step branch-d  $GIT branch -d feature
	step pull      $GIT pull
	step checkout-sha $GIT checkout HEAD~1
	step switch-back $GIT switch main
	$GIT checkout -q -b topic; printf 'topic\n' >b.txt; $GIT commit -qam "topic"
	step push-new  $GIT push
	$GIT switch -q main; printf 'main\n' >b.txt; $GIT commit -qam "main again"
	step merge-conflict $GIT merge topic
	step status-conflict $GIT status
	step merge-abort $GIT merge --abort
	printf 'three\n' >>a.txt
	step diff      $GIT diff
	step commit-nothing $GIT commit -m "nothing"
	cd "$work"
}

GIT_CONFIG_SYSTEM=/dev/null run_scenario "$work/before"
GIT_CONFIG_SYSTEM="$cfg" run_scenario "$work/after"

echo "| Command | Before (bytes) | After (bytes) | Saved |"
echo "|---|---:|---:|---:|"
tb=0; ta=0
for f in $(ls "$work/before" | sort -n); do
	b=$(wc -c <"$work/before/$f" | tr -d ' '); a=$(wc -c <"$work/after/$f" | tr -d ' ')
	tb=$((tb+b)); ta=$((ta+a))
	name=$(printf '%s' "$f" | sed 's/^[0-9]*-//')
	if [ "$b" -gt 0 ]; then pct=$(( (b-a)*100/b )); else pct=0; fi
	printf '| `git %s` | %s | %s | %s%% |\n' "$name" "$b" "$a" "$pct"
done
printf '| **Total** | **%s** | **%s** | **%s%%** |\n' "$tb" "$ta" "$(( (tb-ta)*100/tb ))"
if [ -n "$SHOW" ]; then
	for f in $(ls "$work/before" | sort -n); do
		echo "=== $f (before)"; cat "$work/before/$f"; echo "=== $f (after)"; cat "$work/after/$f"
	done
fi
