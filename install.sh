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
  echo "  --global, -g         Install 'git-push', 'push', and 'pre-push-check' globally to ~/.local/bin (default)"
  echo "  --system, -s         Install globally to /usr/local/bin (requires sudo)"
  echo "  --hooks [threshold]  Install version-controlled pre-push hooks and set your coverage threshold (e.g. ./install.sh --hooks 85)"
  echo "  -h, --help           Display this help message"
  echo ""
  echo -e "${BOLD}HOW TO SET OR CHANGE YOUR COVERAGE THRESHOLD:${NC}"
  echo "  1. During hook setup:     ./install.sh --hooks 85"
  echo "  2. CLI helper:            pre-push-check --set-threshold 85"
  echo "  3. Directly in config:    echo \"85\" > .coverage-threshold"
  echo "  4. Single push override:  MIN_COVERAGE=85 git push"
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
  local desired_threshold="$1"
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

  # Configure Coverage Threshold (User-defined, no fixed amount mandated)
  if [ -n "$desired_threshold" ]; then
    echo "$desired_threshold" > .coverage-threshold
    echo -e "${GREEN}🎯 Target coverage threshold set to ${BOLD}${desired_threshold}%${NC} (.coverage-threshold)${NC}"
  elif [ -f ".coverage-threshold" ]; then
    CURRENT_THRESH="$(cat .coverage-threshold | tr -d '[:space:]')"
    echo -e "${CYAN}🎯 Existing repository coverage threshold detected: ${BOLD}${CURRENT_THRESH}%${NC} (.coverage-threshold)${NC}"
  else
    if [ -t 0 ]; then
      echo ""
      echo -e "${YELLOW}⚙️  Configure Coverage Quality Gate:${NC}"
      echo "   We do not mandate a fixed percentage. Enter your repository's desired target:"
      read -r -p "   Minimum coverage percentage (e.g. 70, 75, 80, 85, 90) [Default: 80]: " INPUT_THRESH
      INPUT_THRESH="${INPUT_THRESH:-80}"
      echo "$INPUT_THRESH" > .coverage-threshold
      echo -e "${GREEN}🎯 Saved ${BOLD}${INPUT_THRESH}%${NC} in .coverage-threshold${NC}"
    else
      echo "80" > .coverage-threshold
      echo -e "${YELLOW}ℹ️  Created .coverage-threshold with initial target 80%.${NC}"
    fi
  fi

  echo ""
  echo -e "${BLUE}====================================================${NC}"
  echo -e "${BOLD}💡 HOW TO CONFIGURE OR CHANGE YOUR THRESHOLD ANYTIME:${NC}"
  echo -e "   1. Edit file directly:   ${BOLD}echo \"<new_value>\" > .coverage-threshold${NC}"
  echo -e "   2. Use CLI helper:       ${BOLD}pre-push-check --set-threshold <new_value>${NC}"
  echo -e "   3. Re-run installer:     ${BOLD}./install.sh --hooks <new_value>${NC}"
  echo -e "   4. Override single push: ${BOLD}MIN_COVERAGE=<new_value> git push${NC}"
  echo -e "${BLUE}====================================================${NC}"
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
    install_repo_hooks "$2"
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
