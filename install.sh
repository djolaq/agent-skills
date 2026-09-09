#!/usr/bin/env bash
# Install agent-skills into supported agent homes (opencode + Claude Code).
# Usage: ./install.sh [--copy|--remove]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
MODE="link"
ACTION="install"

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy" ;;
    --remove) ACTION="remove" ;;
    -h|--help)
      echo "usage: $0 [--copy] [--remove]"
      echo "  --copy      copy instead of symlink (Windows/WSL friendly)"
      echo "  --remove    remove installed skills"
      exit 0
      ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.opencode/skills" # fallback if global config dir differs
)

install_skill() {
  local skill="$1"
  local name target dir
  name="$(basename "$skill")"
  for base in "${TARGETS[@]}"; do
    [ -n "$base" ] || continue
    mkdir -p "$base"
    target="$base/$name"
    if [ "$ACTION" = "remove" ]; then
      [ -e "$target" ] && rm -rf "$target" && echo "removed: $target"
      continue
    fi
    if [ -e "$target" ] && [ "$(readlink "$target" 2>/dev/null || true)" != "$skill" ]; then
      echo "skip (exists): $target" >&2
      continue
    fi
    if [ "$MODE" = "copy" ]; then
      cp -r "$skill" "$target"
      echo "copied:  $target"
    else
      ln -sfn "$skill" "$target"
      echo "linked:  $target"
    fi
  done
}

if [ ! -d "$SKILLS_SRC" ]; then
  echo "no skills directory found at $SKILLS_SRC" >&2
  exit 1
fi

for skill in "$SKILLS_SRC"/*; do
  [ -d "$skill" ] || continue
  [ -f "$skill/SKILL.md" ] || { echo "warn: no SKILL.md in $skill" >&2; continue; }
  install_skill "$skill"
done

echo "done."
echo "Restart opencode / Claude Code for skills to be picked up."