# 🤝 Contributing to git-cli-scripts

First off, thank you for considering contributing to **`git-cli-scripts`**! 🎉

This project was created to empower developers with **branch-aware Git tooling** and **zero-defect local quality gates** where developers and teams—not rigid scripts—own their quality thresholds.

Whether you are fixing a bug, adding validator support for a new language, improving documentation, or proposing new features, your help is welcome!

---

## 📖 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Core Design Principles](#core-design-principles)
- [Repository Tour](#repository-tour)
- [Local Development Setup](#local-development-setup)
- [Coding Guidelines for Shell Scripts](#coding-guidelines-for-shell-scripts)
- [Testing Your Changes Locally](#testing-your-changes-locally)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Ideas for Contributions](#ideas-for-contributions)

---

## Code of Conduct

We are committed to providing a welcoming, inclusive, and harassment-free environment for everyone.
- Treat every contributor with kindness and professional respect.
- Provide constructive, actionable feedback in reviews.
- Focus on what is best for the developer community and open-source users.

---

## Core Design Principles

When contributing code to `git-cli-scripts`, keep these 4 core tenets in mind:

1. **Zero External Dependencies**:
   Scripts must run out-of-the-box using standard tools present on modern UNIX systems (`bash`, `git`, `coreutils`, `awk`, `sed`, `grep`). Never introduce heavy runtime dependencies (like requiring Python, Node, or Ruby just to run the Git CLI wrapper).
2. **User-Owned Thresholds (Never Impose Fixed Numbers)**:
   The toolchain enforces gates strictly, but the *target threshold* is always chosen and configured by the user/team (via `.coverage-threshold`). Never hardcode a mandatory fixed percentage.
3. **Graceful Degradation**:
   If a particular runtime (like Flutter, Go, or Python) is not installed on the developer's machine or not used in the repository, the script should cleanly skip it or detect alternatives without throwing fatal shell crashes.
4. **Rich Terminal Aesthetics & Clean Plaintext**:
   Provide colored, human-friendly output with ANSI escapes, but automatically strip colors when running in headless environments, non-interactive CI pipes, or when `NO_COLOR=1` is set.

---

## Repository Tour

```text
git-cli-scripts/
├── bin/
│   ├── git-push             # Smart commit & push CLI with branch guards & conventional commit checks
│   └── pre-push-check       # Quality validator (analyzer, tests, user-defined coverage)
├── hooks/
│   ├── pre-push             # Git pre-push hook template (invokes pre-push-check)
│   └── post-merge           # Git post-merge hook (keeps permissions intact on git pull)
├── install.sh               # Single-command installer for global tools or repo hooks
├── readme.md                # Main overview and quickstart
├── git_push.md              # In-depth guide for 'git-push' and 'push'
├── pre_push_hooks.md        # In-depth guide for automated pre-push validation gates
├── contribution.md          # Contributor guide (this file)
└── license.md               # MIT License
```

---

## Local Development Setup

### 1. Fork & Clone
Fork the repository on GitHub, then clone your fork:
```bash
git clone https://github.com/<your-username>/git-cli-scripts.git
cd git-cli-scripts
```

### 2. Verify Script Permissions
Ensure all scripts in `bin/` and `hooks/` have executable permissions:
```bash
chmod +x bin/* hooks/* install.sh
```

### 3. Test In-Place Without Overwriting Global Binaries
During development, run the scripts directly from the repository without installing them to `~/.local/bin`:
```bash
./bin/git-push --help
./bin/pre-push-check --help
./bin/pre-push-check --info
```

---

## Coding Guidelines for Shell Scripts

To ensure maximum portability across macOS, Linux, and WSL environments:

### 1. Strict Error Handling
Start every script with:
```bash
#!/usr/bin/env bash
set -e
```
Use `|| true` intentionally only where a non-zero exit code is expected and handled safely.

### 2. Double-Quote All Variables
Always double-quote variables to prevent unintended word splitting and globbing:
```bash
# Correct:
cd "$TARGET_DIR"
echo "$COMMIT_MSG"

# Incorrect:
cd $TARGET_DIR
```

### 3. Safe Terminal Color Handling
Always verify stdout is an interactive terminal (`[ -t 1 ]`) and respect the standard `NO_COLOR` environment variable:
```bash
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  GREEN='\033[0;32m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  GREEN=''
  BOLD=''
  NC=''
fi
```

### 4. Meaningful Exit Codes
- `0`: Success (all checks passed).
- `1`: Validation error / quality gate failure.
- `2`: Invalid CLI arguments or syntax error.

---

## Testing Your Changes Locally

Before submitting changes, test your modifications thoroughly:

### 1. Test CLI Help & Flags
```bash
./bin/git-push --help
./bin/git-push -v
./bin/pre-push-check --help
./bin/pre-push-check -i
./install.sh --help
```

### 2. Test in a Disposable Scratch Repository
You can verify hooks and threshold configuration in an isolated test repo:
```bash
# Create scratch repo
mkdir /tmp/test-hook-repo && cd /tmp/test-hook-repo
git init

# Test hook installation with custom threshold
/path/to/git-cli-scripts/install.sh --hooks 85

# Verify threshold persistence
cat .coverage-threshold # should output 85

# Verify pre-push-check reads it
/path/to/git-cli-scripts/bin/pre-push-check --info

# Clean up
cd .. && rm -rf /tmp/test-hook-repo
```

### 3. Test Shellcheck (If Available)
If you have `shellcheck` installed, run it against modified scripts:
```bash
shellcheck bin/git-push bin/pre-push-check install.sh hooks/*
```

---

## Submitting a Pull Request

1. **Create a Feature Branch**:
   ```bash
   git checkout -b feat/add-rust-validator
   ```
2. **Follow Conventional Commits**:
   Format your commit messages clearly:
   - `feat(validator): add Rust cargo test and clippy support`
   - `fix(hooks): resolve unbound variable in install.sh`
   - `docs(readme): clarify coverage ratchet examples`
3. **Keep Documentation in Sync**:
   If your PR adds a new CLI flag, framework validator, or feature, update:
   - [readme.md](./readme.md)
   - [git_push.md](./git_push.md) or [pre_push_hooks.md](./pre_push_hooks.md)
   - The `--help` output of the affected script
4. **Push & Open PR**:
   Push to your fork and open a Pull Request against the `main` branch. Provide a clear summary of what changed and how you tested it.

---

## Ideas for Contributions

Looking for ways to contribute? Here are some high-impact areas:
- 🦀 **Language Validators**: Add pre-push validators for Rust (`cargo clippy`, `cargo test`), Kotlin, or Swift.
- 🧪 **Monorepo / Workspace Detection**: Enhanced subproject detection for Nx, Turborepo, or Melos.
- 📦 **Package Manager Integrations**: Brew tap formula or Nix package definition.
- 🎨 **Visual Output Polish**: Interactive diff previews or enhanced coverage summary tables.

Thank you for helping make developer toolchains cleaner, faster, and more reliable! 🚀
