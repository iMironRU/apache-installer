# CLAUDE.md — Project Guide for AI Assistants

This file describes the project structure, conventions and common tasks for AI coding assistants (Claude, Copilot, etc.).

## Project Overview

**apache-installer** is a PowerShell-based automated installer for Apache HTTP Server 2.4 on Windows.  
It compiles to a standalone `.exe` via [ps2exe](https://github.com/MScholtes/PS2EXE).

- **Author:** imiron.ru
- **License:** Apache License 2.0
- **Repo:** https://github.com/imiron-ru/apache-installer

---

## Repository Layout

```
apache-installer/
├── src/
│   └── install-apache.ps1       # PRIMARY SOURCE — single multilingual script (en + ru)
├── archive/                     # Legacy files — do NOT modify
│   ├── install-apache-en.ps1    # Old English-only version
│   ├── install-apache-ru.ps1    # Old Russian-only version
│   ├── install-en.bat           # Old launcher
│   └── install-ru.bat           # Old launcher
├── .github/
│   └── workflows/
│       └── nightly-build.yml    # GitHub Actions: nightly EXE build
├── build-exe.bat                # Local build script (calls ps2exe)
├── README.md                    # User-facing documentation (en + ru)
├── CLAUDE.md                    # This file
├── CHANGELOG.md                 # Version history
├── CONTRIBUTING.md              # Contribution guide
└── LICENSE                      # Apache License 2.0
```

---

## Key Conventions

### Language / Localization

- All user-visible strings are in the `$Strings` hashtable at the top of `install-apache.ps1`.
- Language is auto-detected from `$PSUICulture` — starts with `ru` → Russian, otherwise English.
- Override via `-Lang en` or `-Lang ru` parameter.
- **Logs are always in English** regardless of UI language.
- When adding new strings: add to both `en` and `ru` keys in `$Strings`.

### PowerShell Coding Style

- `Set-StrictMode -Version Latest` is active — all variables must be declared.
- `$ErrorActionPreference = 'Stop'` — all errors terminate the script.
- Use `$script:` scope for variables shared across functions.
- Helper functions: `Write-Log`, `Show-Banner`, `Ask-YesNo`, `Get-StringF`, `T` (localized text lookup).
- Never use `Write-Host` for user output — use the `T` function + `Write-Host` combo or dedicated helpers.

### Versioning

- Version is set in `build-exe.bat` and `nightly-build.yml` as `-version`.
- Update `CHANGELOG.md` for every meaningful change.
- Semantic versioning: `MAJOR.MINOR.PATCH`.

---

## Common Tasks

### Add a new UI string

1. Open `src/install-apache.ps1`.
2. Find the `$Strings` hashtable (near the top).
3. Add the key to both `en = @{...}` and `ru = @{...}` blocks.
4. Use `T 'YourKey'` to display it.

### Add a new menu option

1. Add string keys for the option label in `$Strings`.
2. Add the menu item to the `Show-MainMenu` function.
3. Handle the selection in the main `switch` block.

### Build the EXE locally

```bat
build-exe.bat
```
Requires PowerShell 5.1+ and internet access (ps2exe is installed automatically if missing).

### Run without compiling

```powershell
powershell -ExecutionPolicy Bypass -File src\install-apache.ps1
# Or with explicit language:
powershell -ExecutionPolicy Bypass -File src\install-apache.ps1 -Lang ru
```

### Trigger a nightly build manually

Go to **GitHub → Actions → Nightly EXE Build → Run workflow**.

---

## What NOT to touch

- `archive/` — legacy files kept for reference, do not edit or move.
- `.github/workflows/nightly-build.yml` — only change when the build process itself changes.
- `LICENSE` — do not modify.

---

## CI / GitHub Actions

- **Workflow:** `.github/workflows/nightly-build.yml`
- **Schedule:** every night at 02:00 UTC (only if the repo has changed since the last run).
- **Runner:** `windows-latest` (required for ps2exe).
- **Artifact:** `install-apache.exe` uploaded as a release artifact named `nightly-<date>`.
- **Manual trigger:** supported via `workflow_dispatch`.
