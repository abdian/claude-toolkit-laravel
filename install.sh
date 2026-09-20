#!/usr/bin/env bash
# ---------------------------------------------------------------
#  Claude Code toolkit installer
#
#  Usage:  bash install.sh                  → starter 6, into THIS project
#          bash install.sh --all            → all 18, into THIS project
#          bash install.sh --all --global   → all 18, into ~/.claude/skills
#          bash install.sh --all --copy     → real copies instead of symlinks
#          bash install.sh --all --force    → overwrite what's already there
#
#  Default is PROJECT scope + SYMLINK:
#    skills land in <toolkit-parent>/.claude/skills/, applying to this
#    project only. Where real symlinks work (Linux, macOS, Windows with
#    Developer Mode) there is one copy on disk and edits take effect at
#    once; otherwise real copies are installed and you re-run with --force
#    after editing a skill. The script tells you which one you got.
#
#  NOTE: a personal skill (~/.claude/skills/) OVERRIDES a project skill of
#  the same name. If you installed globally before, --global stays global
#  or you will keep running the old copy.
# ---------------------------------------------------------------
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/skills"
ROOT="$(dirname "$HERE")"          # the workspace/project dir holding this toolkit

STARTER=(start next brief plan-check fix-one lazy)
REST=(edges debt spec-import explain security-review ctx-audit ctx-interview ctx-generate ctx-verify ctx-learn audit-codebase find-overengineering)

SET=("${STARTER[@]}")
SCOPE="project"; MODE="link"; FORCE="no"

# ${1+"$@"} not "$@": under `set -u`, bash 4.3 and older (the /bin/bash macOS
# still ships, 3.2) treat an empty "$@" as unbound and abort a no-arg run.
for arg in ${1+"$@"}; do
  case "$arg" in
    --all)     SET=("${STARTER[@]}" "${REST[@]}") ;;
    --global)  SCOPE="global" ;;
    --project) SCOPE="project" ;;
    --copy)    MODE="copy" ;;
    --link)    MODE="link" ;;
    --force)   FORCE="yes" ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [ "$SCOPE" = "global" ]; then
  DEST="$HOME/.claude/skills"
else
  DEST="$ROOT/.claude/skills"
fi

# Git Bash on Windows silently COPIES when it can't make a real symlink —
# ln -s still exits 0. Test the result, not the exit code.
if [ "$MODE" = "link" ]; then
  probe="$(mktemp -d)"
  ln -s "$SRC" "$probe/probe" 2>/dev/null || true
  if [ ! -L "$probe/probe" ]; then
    echo "  ! real symlinks unavailable here — installing real copies instead."
    echo "    edits in $SRC/ will NOT propagate; re-run with --force"
    echo "    after changing a skill. (Windows: enabling Developer Mode, or"
    echo "    setting MSYS=winsymlinks:nativestrict, gives you real symlinks.)"
    echo
    MODE="copy"
  fi
  rm -rf "$probe"
fi

mkdir -p "$DEST"
echo "→ scope : $SCOPE"
echo "→ dest  : $DEST"
echo "→ mode  : $MODE$([ "$FORCE" = yes ] && echo " (overwriting)")"
echo

installed=0; skipped=0
for s in "${SET[@]}"; do
  if [ ! -f "$SRC/$s/SKILL.md" ]; then
    echo "  ✗ $s  — not found in $SRC, skipping"
    continue
  fi
  if [ -e "$DEST/$s" ] || [ -L "$DEST/$s" ]; then
    if [ "$FORCE" = "yes" ]; then
      rm -rf "$DEST/$s"
    else
      echo "  · $s  — already there, left alone (use --force to update)"
      skipped=$((skipped+1)); continue
    fi
  fi
  if [ "$MODE" = "link" ]; then
    ln -s "$SRC/$s" "$DEST/$s"
    if [ -L "$DEST/$s" ]; then echo "  ✓ $s  (symlink)"; else echo "  ✓ $s  (copy — link failed)"; fi
  else
    cp -R "$SRC/$s" "$DEST/$s"
    echo "  ✓ $s"
  fi
  installed=$((installed+1))
done

echo
echo "done. installed: $installed · left alone: $skipped"
if [ "$skipped" -gt 0 ]; then
  echo "      re-run with --force to refresh the ones left alone."
fi
echo

if [ "$SCOPE" = "project" ]; then
  echo "next:"
  echo "  1. run 'claude' from:  $ROOT"
  echo "     (project skills load from the directory you start in, and from"
  echo "      .claude/skills below it — not from directories above it)"
  echo "  2. type: /skills   to confirm they loaded"
  echo
  echo "  commit .claude/skills/ if you want teammates to get them too."
else
  echo "next:  restart Claude Code once, then run 'claude' anywhere and type /skills"
fi
echo
echo "note (Windows): run this from Git Bash or WSL, not cmd/PowerShell."
