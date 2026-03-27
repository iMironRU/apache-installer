# Contributing to Apache Installer

Thank you for your interest in contributing!  
Copyright (c) 2026 [imiron.ru](https://imiron.ru) — Apache License 2.0

---

## Ways to Contribute

- 🐛 **Bug reports** — open an Issue with the log file attached
- 💡 **Feature requests** — open an Issue describing the use case
- 🔧 **Pull requests** — fixes and improvements are welcome
- 🌐 **Translations** — new language versions (follow `en`/`ru` pattern)

---

## Before You Start

1. Check existing [Issues](../../issues) — your idea may already be discussed
2. For significant changes, open an Issue first to discuss the approach
3. One pull request per feature or fix

---

## Development Setup

No special tools required — just PowerShell 5.1+.

```powershell
# Clone the repo
git clone https://github.com/imiron-ru/apache-installer.git
cd apache-installer

# Run directly (no compilation needed)
powershell -ExecutionPolicy Bypass -File src\install-apache-en.ps1

# Optional: compile to exe for testing
Install-Module -Name ps2exe -Scope CurrentUser -Force
.\build-exe.bat
```

---

## Code Style

**PowerShell:**
- Use `$PascalCase` for functions, `$camelCase` for local variables, `$UPPER_CASE` for constants
- All user-facing strings must have equivalents in both `en` and `ru` versions
- No Cyrillic characters inside single quotes `'...'` — use double quotes `"..."` for strings containing Cyrillic
- Every significant operation must call `Write-Log`
- Wrap destructive operations in `try/catch` with `Invoke-Cleanup` on failure
- New features should work both as `.ps1` and compiled `.exe` (test `$isExe` path)

**Adding a new language:**
1. Copy `src/install-apache-en.ps1` → `src/install-apache-XX.ps1`
2. Translate all user-facing strings
3. Copy `install-en.bat` → `install-XX.bat`, update path
4. Add the language to `build-exe.bat`
5. Add a section to `README.md`

---

## Pull Request Checklist

- [ ] Tested on Windows 10/11 as `.ps1`
- [ ] Tested as compiled `.exe` (if ps2exe is available)
- [ ] Both `en` and `ru` versions updated (if adding user-facing strings)
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] No Cyrillic in single quotes
- [ ] Log messages added for new operations

---

## Bug Reports

Please include:

1. Windows version (`winver`)
2. PowerShell version (`$PSVersionTable.PSVersion`)
3. Running as `.ps1` or compiled `.exe`
4. The full `install-apache-*.log` file from the same folder as the script
5. Steps to reproduce

---

## Attribution

By contributing, you agree that your contributions will be licensed under the same [Apache License 2.0](LICENSE).  
Please keep the copyright notice `Copyright (c) 2026 imiron.ru` intact in all files.
