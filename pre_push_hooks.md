# 🛡️ Opinionated Pre-Push Hooks — Automated Quality & Coverage Gates

> Enforce strict static analysis, 100% passing test suites, and production code coverage gates directly on developers' machines before code ever reaches remote branches or pull requests.

---

## 📖 Table of Contents

- [The Opinionated Quality Stance](#the-opinionated-quality-stance)
- [Why Fixed 70% is Flawed & What We Do Instead](#why-fixed-70-is-flawed--what-we-do-instead)
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
- [Customizing the Coverage Threshold](#customizing-the-coverage-threshold)
- [Emergency Bypass (`--no-verify`)](#emergency-bypass---no-verify)
- [Troubleshooting](#troubleshooting)

---

## The Opinionated Quality Stance

In most software teams, code quality is enforced after the fact:
1. Developers push code.
2. Cloud CI/CD builds run 10 minutes later.
3. CI fails due to a missed linter warning, a broken test, or degraded test coverage.
4. The developer switches context, pulls, fixes, and pushes again.

**Our opinionated stance is simple:**
> **Remote CI should be a formal stamp of approval, never a debugging environment.**
> If your code doesn't pass strict static analysis, if tests fail, or if test coverage drops below production standards, **it must not leave your machine.**

---

## Why Fixed 70% is Flawed & What We Do Instead

Many early tutorials suggest an arbitrary `70%` coverage target. In practice, fixed 70% has notable flaws:
- **30% Untested Surface**: In a 10,000-line application, 70% coverage leaves **3,000 lines of unverified production code**.
- **One Size Doesn't Fit All**: A security-critical authentication microservice might mandate **`90%`**, while an exploratory UI prototype might need **`75%`**.
- **The "Good Enough" Plateau**: Developers write tests only until they hit 70.01% and stop, even if critical business logic remains unexercised.

### The Opinionated Solution:
1. **Opinionated Default (80%)**: We default to **`80.00%`**—the widely recognized engineering standard for resilient production software (Google, Martin Fowler, ISO).
2. **Explicit Project-Defined Gates (`.coverage-threshold`)**: Each repository explicitly declares its required threshold in a `.coverage-threshold` file (e.g. `85` or `90`).
3. **Zero-Warning Static Analysis**: Static analysis is not a suggestion. A single lint warning or analysis issue aborts the push immediately.

---

## How `pre-push-check` Operates

`pre-push-check` automatically inspects the repository and applies framework-specific opinionated gates:

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
🛡️  OPINIONATED PRE-PUSH GATE: my_flutter_app
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
🎉 All opinionated quality gates passed successfully!
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

You can implement these opinionated gates in **any repository** in under 2 minutes:

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

echo "🔧 Configuring opinionated Git hooks for $(basename "$REPO_ROOT")..."
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
git commit -m "chore(quality): enforce opinionated pre-push quality gates"
git push
```

---

## Customizing the Coverage Threshold

Instead of a generic 70%, define your team's exact target:

### Method A: `.coverage-threshold` File (Recommended)
Add a `.coverage-threshold` file in your repository root:
```bash
echo "85" > .coverage-threshold
git add .coverage-threshold
git commit -m "chore: set coverage gate to 85%"
```

### Method B: Environment Variable Override
```bash
MIN_COVERAGE=90 git push
```

---

## Emergency Bypass (`--no-verify`)

In genuine production emergencies where an immediate hotfix must bypass local validation:

```bash
git push --no-verify
```

> ⚠️ **Warning**: Use `--no-verify` exclusively for incident response hotfixes.

---

## Troubleshooting

### Q: `OPINIONATED GATE FAILED: Coverage is below required threshold`
**Why**: Your overall test coverage does not meet the project's required gate (e.g. 80%).
**Solution**: Run tests locally with coverage (`flutter test --coverage` or `npm test -- --coverage`) and write tests covering modified or newly added code paths.

### Q: `flutter analyze found issues`
**Why**: Static analyzer detected dead code, unused imports, or lint errors.
**Solution**: Fix all warnings and run `flutter analyze` until 0 issues remain.
