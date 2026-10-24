# 🛠️ git-cli-scripts

> An **opinionated** developer toolchain to automate active-branch Git pushes and enforce zero-defect local pre-push quality gates (static analysis, unit tests, and production code coverage).

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Philosophy: Opinionated](https://img.shields.io/badge/Quality-Opinionated%20Gates-red.svg)](#-the-opinionated-manifest)
[![Shell](https://img.shields.io/badge/Shell-Bash%20%7C%20Zsh-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![Flutter](https://img.shields.io/badge/Support-Flutter%20%2F%20Dart-02569B.svg)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Support-Node.js%20%2F%20TypeScript-339933.svg)](https://nodejs.org)
[![Python](https://img.shields.io/badge/Support-Python-3776AB.svg)](https://python.org)
[![Go](https://img.shields.io/badge/Support-Go-00ADD8.svg)](https://go.dev)

---

## 🏛️ The Opinionated Manifest

Most engineering teams rely on cloud CI/CD pipelines to catch bugs. But cloud runners are slow, costly, and provide feedback 10 minutes too late.

`git-cli-scripts` takes an **uncompromising, opinionated stance**: **remote CI should be a formal stamp of approval, never a debugging tool.** Broken code, flaky tests, and untested features must never leave a developer's laptop.

### 4 Core Opinionated Gates

1. 🔍 **Zero Broken Windows (Zero-Tolerance Lints)**:
   Compiler and linter warnings are treated as hard failures. If `flutter analyze` or `npm run lint` reports issues, the push is terminated immediately.
2. 🧪 **100% Green Test Suite**:
   Every unit, widget, and integration test must pass. A single failing test blocks the push.
3. 📊 **Enforced Production Coverage Thresholds**:
   Coverage is not an afterthought. Projects define their strict quality gate (default: `>= 80%`, configurable per repo via `.coverage-threshold`). Drops in coverage are blocked before reaching remote.
4. 🛡️ **Branch Hygiene & Protected Branch Guards**:
   Accidental pushes to `main`, `master`, or `production` are guarded with interactive confirmation. Pushes from detached HEAD states are completely prohibited.

---

## 🧰 The Toolchain

| Tool | Purpose | Primary Command |
| :--- | :--- | :--- |
| **`git-push`** / **`push`** | Opinionated branch-aware push. Validates conventional commits, protects production branches, and pushes active branches with upstream tracking. | `push "feat: my commit"` |
| **`pre-push-check`** | Opinionated pre-push quality gatekeeper. Auto-detects Flutter, Node/TS, Python, or Go, enforcing zero-defect analysis, tests, and coverage. | `git push` (hook) or `pre-push-check` |

---

## 📁 Repository Structure

```text
git-cli-scripts/
├── bin/
│   ├── git-push             # Smart commit & push CLI with branch guards & conventional commit checks
│   └── pre-push-check       # Opinionated quality validator (analyzer, tests, coverage gates)
├── hooks/
│   ├── pre-push             # Git pre-push hook template (invokes pre-push-check)
│   └── post-merge           # Git post-merge hook (keeps permissions intact on git pull)
├── install.sh               # Single-command installer for global tools or repo hooks
├── readme.md                # Main overview and quickstart (this file)
├── git_push.md              # In-depth guide for 'git-push' and 'push'
└── pre_push_hooks.md        # In-depth guide for opinionated pre-push validation gates
```

---

## ⚡ 1-Minute Quickstart

### 1. Install CLI Tools Globally on Your Machine

```bash
# Clone the repository
git clone https://github.com/appframesystems/git-cli-scripts.git ~/git-cli-scripts

# Run installer (installs to ~/.local/bin)
cd ~/git-cli-scripts
./install.sh
```

Ensure `~/.local/bin` is in your `$PATH` (in `~/.zshrc` or `~/.bashrc`):
```bash
export PATH="$HOME/.local/bin:$PATH"
```

Now you can use `push` from **any terminal session**:
```bash
# Inside any repository:
push "feat(auth): add refresh token support"

# From a multi-repo parent workspace:
push client "fix(ui): repair mobile layout overflow"
```

---

### 2. Configure Opinionated Gates for Any Repository

Want your repository to enforce strict quality gates automatically for everyone on your team?

Navigate to your project root and run:
```bash
cd /path/to/your/repository
~/git-cli-scripts/install.sh --hooks
```

This installs version-controlled hooks into `.githooks/` and configures Git:
```bash
git config core.hooksPath .githooks
```

Commit `.githooks/` to your repository:
```bash
git add .githooks
git commit -m "chore(quality): enforce opinionated pre-push gates"
git push
```

Now, **every team member who pulls or clones your repository** will automatically run static analysis, tests, and coverage validation before every push!

---

## ⚙️ Customizing the Coverage Gate

To set a custom coverage threshold for your project (e.g. 85%), simply create a `.coverage-threshold` file in your repository root:

```bash
echo "85" > .coverage-threshold
```

`pre-push-check` will automatically read and enforce this target.

---

## 📚 In-Depth Guides

- **[`git_push.md`](./git_push.md)**:
  - Branch detection and detached HEAD guards.
  - Protected production branch prompts (`main`/`master`).
  - Conventional Commits hygiene.
  - Standalone repo vs. multi-repo parent workspace usage.
- **[`pre_push_hooks.md`](./pre_push_hooks.md)**:
  - Deep-dive into opinionated pre-push quality gates.
  - Language-specific configurations (Flutter, Node/TS, Python, Go).
  - Version-controlling hooks via `.githooks` across distributed teams.
  - Emergency bypass flags (`--no-verify`).

---

## 📄 License

Distributed under the [MIT License](https://opensource.org/licenses/MIT). You are free to adopt, modify, distribute, and open-source this suite for personal or corporate development.
