# Changelog

All notable changes to this project will be documented in this file.

Format: [Semantic Versioning](https://semver.org)  
Copyright (c) 2026 [imiron.ru](https://imiron.ru)

---

## [1.0.0] — 2026-03-27

### Added
- Initial release
- Automated download of Apache HTTP Server 2.4 from apachelounge.com
- Auto-detection of OS architecture (x86 / x64)
- Visual C++ Redistributable check and auto-install
- Multiple Apache instances support on different ports
- Instance registry via Windows Registry (`HKLM\SOFTWARE\ApacheInstaller`)
- Instance discovery via SCM scan (catches manually installed Apache too)
- Interactive menus: folder, port selection with defaults
- Port status display (free / busy with process name and PID)
- Disk space check before installation and backup
- Backup before reinstall or remove (config only / full / both / skip)
- Backup compression to `.zip` via `Compress-Archive`
- Windows Firewall rule management (prevents Security Alert popup)
- Service registration with custom name `Apache_<port>`
- HTTP verification after installation
- Full operation logging with timestamps to `install-apache-*.log`
- Custom `index.html` with server info and link to install log
- Removal mode with instance selection from discovered list
- ps2exe compatibility (works as `.ps1` and compiled `.exe`)
- English (`-en`) and Russian (`-ru`) versions
- `install-en.bat` and `install-ru.bat` launchers with auto-UAC elevation
- `build-exe.bat` for automated ps2exe compilation of both versions
- Cleanup on error (removes partially installed files and service)

### Security
- `ServerTokens Prod` — hides Apache version
- `ServerSignature Off` — no server signature on error pages
- `TraceEnable Off` — XST attack protection
- Security headers: `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`
- `/server-status` restricted to `127.0.0.1` only
- `mod_authz_host` loaded for `Require ip` support
- `Listen <port>` without IP binding (avoids AH00072 on Windows)
- `Options -Indexes` — directory listing disabled
