#!/usr/bin/env bash
# ==============================================================================
# Installer for git-cli-scripts
# Part of git-cli-scripts (https://github.com/appframesystems/git-cli-scripts)
# License: MIT
# ==============================================================================
set -e

# Terminal colors
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  GREEN='\033[0;32m'
  BLUE='\033[0;34m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  GREEN=''
  BLUE=''
  YELLOW=''
  RED=''
  BOLD=''
  NC=''
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
  echo -e "${BOLD}git-cli-scripts Installer${NC}"
  echo ""
  echo -e "${BOLD}USAGE:${NC}"
  echo "  ./install.sh [OPTION]"
  echo ""
  echo -e "${BOLD}OPTIONS:${NC}"
  echo "  --global, -g    Install 'git-push', 'push', and 'pre-push-check' globally to ~/.local/bin (default)"
  echo "  --system, -s    Install globally to /usr/local/bin (requires sudo)"
  echo "  --hooks         Install version-controlled pre-push hooks into current Git repository (.githooks/)"
  echo "  -h, --help      Display this help message"
}

install_global() {
  local target_dir="$1"
  echo -e "${BLUE}🔧 Installing git-cli-scripts to ${BOLD}${target_dir}${NC}...${NC}"

  mkdir -p "$target_dir"

  # Copy binaries
  cp "$SCRIPT_DIR/bin/git-push" "$target_dir/git-push"
  cp "$SCRIPT_DIR/bin/pre-push-check" "$target_dir/pre-push-check"

  chmod +x "$target_dir/git-push"
  chmod +x "$target_dir/pre-push-check"

  # Create symlink 'push' -> 'git-push'
  ln -sf "$target_dir/git-push" "$target_dir/push"

  echo -e "${GREEN}✅ Installed 'git-push', 'push', and 'pre-push-check' into ${target_dir}!${NC}"

  # Check PATH
  if [[ ":$PATH:" != *":$target_dir:"* ]]; then
    echo -e "${YELLOW}⚠️  Note: ${target_dir} is not yet in your current PATH.${NC}"
    echo -e "   Add this to your ~/.zshrc or ~/.bashrc:"
    echo -e "   ${BOLD}export PATH=\"${target_dir}:\$PATH\"${NC}"
  fi
}

install_repo_hooks() {
  local repo_dir="$(pwd)"
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: $(pwd) is not a Git repository.${NC}"
    exit 1
  fi

  echo -e "${BLUE}🔧 Setting up version-controlled hooks in $(basename "$repo_dir")...${NC}"

  mkdir -p ".githooks"
  cp "$SCRIPT_DIR/hooks/pre-push" ".githooks/pre-push"
  cp "$SCRIPT_DIR/hooks/post-merge" ".githooks/post-merge"
  chmod +x .githooks/*

  # Configure git to use .githooks
  git config core.hooksPath .githooks

  # Also copy to .git/hooks as fallback
  if [ -d ".git/hooks" ]; then
    cp .githooks/pre-push .git/hooks/pre-push
    chmod +x .git/hooks/pre-push
  fi

  echo -e "${GREEN}✅ Git pre-push hook active via .githooks/!${NC}"
  echo -e "   Commit .githooks/ to share with team members automatically."
}

MODE="${1:-global}"

case "$MODE" in
  --global|-g|global)
    install_global "$HOME/.local/bin"
    ;;
  --system|-s|system)
    install_global "/usr/local/bin"
    ;;
  --hooks|hooks)
    install_repo_hooks
    ;;
  -h|--help)
    show_help
    exit 0
    ;;
  *)
    echo -e "${RED}Unknown option: $MODE${NC}"
    show_help
    exit 1
    ;;
esac
