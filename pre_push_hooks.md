# 🛡️ Pre-Push Hooks — Automated Quality & Coverage Gates

> Enforce strict static analysis, 100% passing test suites, and production code coverage gates directly on developers' machines before code ever reaches remote branches or pull requests.

---

## 📖 Table of Contents

- [The Quality Philosophy](#the-quality-philosophy)
- [User-Defined Quality Gates: No Mandated Fixed Amounts](#user-defined-quality-gates-no-mandated-fixed-amounts)
- [How to Set, Inspect, or Change Your Coverage Threshold](#how-to-set-inspect-or-change-your-coverage-threshold)
- [How `pre-push-check` Operates](#how-pre-push-check-operates)
  - [1. Flutter & Dart](#1-flutter--dart)
  - [2. Node.js & TypeScript](#2-nodejs--typescript)
  - [3. Python](#3-python)
  - [4. Go](#4-go)
- [Step-by-Step Implementation in Any Repository](#step-by-step-implementation-in-any-repository)
  - [Step 1: Create the Version-Controlled `.githooks` Directory](#step-1-create-the-version-controlled-githooks-directory)
  - [Step 2: Add the `pre-push` Hook](#step-2-add-the-pre-push-hook)
  - [Step 3: Add the `post-merge` Hook](#step-3-add-the-post-merge-hook)
  - [Step 4: Configure Git to Use `.githooks`](#step-4-configure-git-to-use-githooks)
  - [Step 5: Provide a 1-Line Onboarding Setup Script](#step-5-provide-a-1-line-onboarding-setup-script)
- [Emergency Bypass (`--no-verify`)](#emergency-bypass---no-verify)
- [Troubleshooting](#troubleshooting)

---

## The Quality Philosophy

In most software teams, code quality is enforced after the fact:
1. Developers push code.
2. Cloud CI/CD builds run 10 minutes later.
3. CI fails due to a missed linter warning, a broken test, or degraded test coverage.
4. The developer switches context, pulls, fixes, and pushes again.

**Our quality philosophy is simple:**
> **Remote CI should be a formal stamp of approval, never a debugging environment.**
> If your code doesn't pass strict static analysis, if tests fail, or if test coverage drops below your target, **it must not leave your machine.**

---

## User-Defined Quality Gates: No Mandated Fixed Amounts

Many legacy tools and tutorials attempt to impose an arbitrary fixed amount—for example, hardcoding `>= 70%` or `>= 80%`.

In production engineering, **fixed tool-imposed amounts do not work**:
- **Every repository has unique needs**: A security-critical authentication microservice might require **`95%`**, an established mobile app might hold **`80%`**, while a newly inherited legacy monolith might currently sit at **`55%`**.
- **Fixed numbers encourage cheating**: When tools impose an arbitrary number, developers write hollow boilerplate tests purely to cross the line, without testing real failure scenarios.
- **Tools shouldn't make architectural decisions for your team**: Your engineering team knows the maturity and criticality of your code better than any generic tool.

### User-Defined Standards

> **We do not tell you what your threshold must be. We strictly enforce whatever target you choose.**
> **You enter your own threshold, and the toolchain strictly enforces your target on every single push.**

You have complete control to set your threshold. Once configured:
1. **Zero tolerance for regression**: Any push dropping below your configured target is immediately blocked.
2. **Clear guidance**: If a check fails, the tool displays the exact line deficit and instructions on how to meet or adjust the threshold.
3. **Team alignment**: Your threshold is committed to `.coverage-threshold` in Git, so everyone on the team adheres to the exact same standard.

---

## How `pre-push-check` Operates

`pre-push-check` automatically inspects the repository and applies framework-specific quality gates:

### 1. Flutter & Dart
Detected via `pubspec.yaml`:
- **Step 1: Zero-Tolerance Analysis**: Runs `flutter analyze`. If any warning or issue is found, the push is terminated.
- **Step 2: 100% Green Tests**: Runs `flutter test --coverage`. All unit, widget, and integration tests must pass.
- **Step 3: Coverage Gate**:
  - Automatically parses `coverage/lcov.info`.
  - Calculates line coverage with basis point accuracy.
  - If coverage is below the target (e.g. `78.2% < 80.0%`), the push is blocked and the exact line deficit is reported.

```text
====================================================
🛡️  PRE-PUSH QUALITY GATE: my_flutter_app
   Target Coverage:   >= 80.00%
   Analysis Policy:   Zero-Tolerance (0 issues)
====================================================
📱 Project Type: Flutter / Dart
🔍 Step 1/3: Running flutter analyze...
✅ Analysis passed: 0 issues found.
🧪 Step 2/3: Running flutter test --coverage...
✅ All Flutter tests passed!
📊 Step 3/3: Evaluating code coverage against 80% gate...
   Total Executable Lines: 12450
   Covered Lines:          10210
   Overall Coverage:       82.00% (Required: >= 80.00%)
✅ Coverage gate passed! (82.00% >= 80.00%)
====================================================
🎉 All quality gates passed successfully!
====================================================
```

### 2. Node.js & TypeScript
Detected via `package.json`:
- **Package Manager Detection**: Supports `pnpm`, `npm`, `yarn`, and `bun`.
- **Linter Check**: If `"lint"` is in `package.json`, runs `npm run lint`.
- **Test Suite**: If `"test"` is in `package.json`, runs `npm test`.

### 3. Python
Detected via `pyproject.toml`, `requirements.txt`, or `setup.py`:
- **Linter**: Runs `ruff check .` or `flake8 .`.
- **Tests**: Runs `pytest`.

### 4. Go
Detected via `go.mod`:
- **Analysis**: Runs `go vet ./...`.
- **Tests & Coverage**: Runs `go test -cover ./...`.

---

## Step-by-Step Implementation in Any Repository

You can implement these quality gates in **any repository** in under 2 minutes:

### Step 1: Create the Version-Controlled `.githooks` Directory

Git's default `.git/hooks/` directory cannot be committed to Git. By using `.githooks/` in the project root, your quality gates are version-controlled and shared across the entire team.

```bash
mkdir -p .githooks
```

---

### Step 2: Add the `pre-push` Hook

Create `.githooks/pre-push`:

```bash
cat << 'EOF' > .githooks/pre-push
#!/usr/bin/env bash
set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Check if pre-push-check is installed globally or in scripts/
if command -v pre-push-check >/dev/null 2>&1; then
  pre-push-check
elif [ -f "./scripts/pre-push-check" ]; then
  ./scripts/pre-push-check
else
  # Inline fallback validation
  if [ -f "pubspec.yaml" ]; then
    echo "🔍 Running Flutter analyze..."
    flutter analyze
    echo "🧪 Running Flutter test..."
    flutter test
  elif [ -f "package.json" ]; then
    if grep -q '"lint"' package.json 2>/dev/null; then
      npm run lint
    fi
  fi
fi

exit 0
EOF

chmod +x .githooks/pre-push
```

---

### Step 3: Add the `post-merge` Hook

Git checkout operations can sometimes reset execution bits. The `post-merge` hook runs automatically after `git pull` to keep hooks executable:

```bash
cat << 'EOF' > .githooks/post-merge
#!/usr/bin/env bash
set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

if [ -d ".githooks" ]; then
  chmod +x .githooks/* 2>/dev/null || true
fi

exit 0
EOF

chmod +x .githooks/post-merge
```

---

### Step 4: Configure Git to Use `.githooks`

Run this command once in your repository to activate the directory:

```bash
git config core.hooksPath .githooks
```

---

### Step 5: Provide a 1-Line Onboarding Setup Script

To ensure new teammates or CI environments configure hooks automatically on clone:

```bash
mkdir -p scripts
cat << 'EOF' > scripts/install_git_hooks.sh
#!/usr/bin/env bash
set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "🔧 Configuring Git quality hooks for $(basename "$REPO_ROOT")..."
git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true

# Fallback copy to .git/hooks
if [ -d ".git/hooks" ]; then
  cp .githooks/pre-push .git/hooks/pre-push
  chmod +x .git/hooks/pre-push
fi

echo "✅ Pre-push quality gate is active!"
EOF

chmod +x scripts/install_git_hooks.sh
```

Now commit these files to your repository:
```bash
git add .githooks scripts
git commit -m "chore(quality): enforce automated pre-push quality gates"
git push
```

---

## How to Set, Inspect, or Change Your Coverage Threshold

You and your team have 100% control over your coverage targets. Here are the 5 ways to configure and manage your quality threshold:

### Method 1: Set Target During Hook Setup (Recommended for New Repos)
When installing version-controlled hooks into your repository, pass your target percentage directly:
```bash
./install.sh --hooks 85
```
Or run without arguments to be prompted interactively:
```bash
./install.sh --hooks
# Prompt: Minimum coverage percentage (e.g. 70, 75, 80, 85, 90) [Default: 80]: 85
```

---

### Method 2: Set or Update via CLI Helper
From anywhere inside your repository workspace:
```bash
pre-push-check --set-threshold 85
```
This updates `.coverage-threshold` instantly.

---

### Method 3: Set Directly via Configuration File
You can write directly to `.coverage-threshold` in the repository root:
```bash
echo "85" > .coverage-threshold
git add .coverage-threshold
git commit -m "chore: set coverage gate threshold to 85%"
```

---

### Method 4: Inspect the Active Threshold
Want to verify which threshold is currently active and where it came from?
```bash
pre-push-check --info
```
Output:
```text
Coverage Threshold Configuration for my_project:
  Current Threshold: 85% (.coverage-threshold)

💡 To change your threshold:
  pre-push-check --set-threshold <new_percentage>
  echo "<new_percentage>" > .coverage-threshold
```

---

### Method 5: Temporary Single-Push Environment Override
To test a higher standard or temporarily override the threshold for a single push without modifying the repository file:
```bash
MIN_COVERAGE=90 git push
```

---

### 📈 Best Practice: The "Coverage Ratchet" Strategy
Never feel pressured to start with an unrealistically high number on an existing or legacy codebase:
1. **Discover Current Baseline**: Run `pre-push-check --threshold 0` to see your current line coverage (e.g. `58.4%`).
2. **Set Initial Floor**: Set your threshold at or slightly above your baseline (e.g. `pre-push-check --set-threshold 60`).
3. **Ratchet Upward Sprint-by-Sprint**: As new features are built with full test coverage, raise the gate incrementally (e.g. `65%` -> `70%` -> `75%` -> `80%`).
4. **Never Regress**: The quality gate guarantees that once a milestone is achieved, no developer can accidentally pull coverage back down.

---

## Emergency Bypass (`--no-verify`)

In genuine production emergencies where an immediate hotfix must bypass local validation:

```bash
git push --no-verify
```

> ⚠️ **Warning**: Use `--no-verify` exclusively for incident response hotfixes.

---

## Troubleshooting

### Q: `QUALITY GATE FAILED: Coverage is below your configured threshold`
- **Why**: Your overall test coverage does not meet the repository's configured `.coverage-threshold` (e.g. `82.4% < 85.0%`).
- **Solution 1 (Write Tests)**: Run tests locally with coverage (`flutter test --coverage` or `npm test -- --coverage`) and write tests covering newly added or modified lines.
- **Solution 2 (Adjust Threshold)**: If your team decides to adjust the project target, run `pre-push-check --set-threshold <new_value>` or edit `.coverage-threshold`.

### Q: `flutter analyze found issues`
- **Why**: Static analyzer detected dead code, unused imports, or lint errors.
- **Solution**: Fix all warnings and run `flutter analyze` until 0 issues remain.

### Q: How do I bypass hooks for a production incident hotfix?
- **Solution**: Pass `--no-verify` to git push: `git push --no-verify` (use only for emergency incident response).

---

## 🔗 Related Resources

- **[`readme.md`](./readme.md)**: Main suite overview and quickstart guide.
- **[`git_push.md`](./git_push.md)**: Active-branch push CLI guide.
- **[`contribution.md`](./contribution.md)**: Open-source contribution guidelines.
- **[`license.md`](./license.md)**: MIT License terms.

