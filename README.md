# Apache HTTP Server Installer for Windows

> Automated installer for Apache HTTP Server 2.4 on Windows.  
> Supports multiple instances, backups, firewall management and ps2exe compilation.  
> **Single multilingual script** — language auto-detected from system locale (en / ru).

**Copyright (c) 2026 [imiron.ru](https://imiron.ru)**  
Licensed under the [Apache License 2.0](LICENSE)

---

## 🌐 Language / Язык

- [English](#english)
- [Русский](#русский)

---

## English

### Features

- ✅ Auto-detects OS architecture (x86 / x64)
- ✅ Checks and installs Visual C++ Redistributable automatically
- ✅ Multiple Apache instances on different ports
- ✅ Instance registry via Windows Registry (no JSON files, location-independent)
- ✅ Automatic backup (config only or full folder) before reinstall / remove
- ✅ Disk space check before installation and backup
- ✅ Windows Firewall rule management (no Security Alert popup)
- ✅ Full operation logging with timestamps
- ✅ Compatible with [ps2exe](https://github.com/MScholtes/PS2EXE) — compile to standalone `.exe`
- ✅ **Single script** with auto-detected language (en / ru), override via `-Lang en|ru`

### Requirements

| Requirement | Details |
|---|---|
| OS | Windows 7 SP1 or newer |
| PowerShell | 5.1 or newer |
| Rights | Administrator |
| Network | Internet access (to download Apache) |

### Quick Start

**Option A — Run compiled exe (recommended):**
```
install-apache.exe
```

**Option B — PowerShell directly:**
```powershell
powershell -ExecutionPolicy Bypass -File src\install-apache.ps1
```

**Option C — Force language:**
```powershell
powershell -ExecutionPolicy Bypass -File src\install-apache.ps1 -Lang ru
```

### Build EXE

Run `build-exe.bat` — it will install ps2exe if needed and compile the script:
```
build-exe.bat
```

Or manually:
```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force
Import-Module ps2exe
Invoke-ps2exe .\src\install-apache.ps1 .\install-apache.exe -requireAdmin -noConsole:$false
```

> Nightly builds are produced automatically via GitHub Actions (`.github/workflows/nightly-build.yml`)  
> and published as release artifacts when the repository changes.

### Repository Structure

```
apache-installer/
├── src/
│   └── install-apache.ps1       # Multilingual installer (en + ru)
├── archive/                     # Legacy separate-language versions
│   ├── install-apache-en.ps1
│   ├── install-apache-ru.ps1
│   ├── install-en.bat
│   └── install-ru.bat
├── .github/
│   └── workflows/
│       └── nightly-build.yml    # Nightly EXE build via ps2exe
├── screenshots/                  # Demo screenshots
├── build-exe.bat                 # Compile to exe via ps2exe
├── README.md
├── CLAUDE.md                     # Project guide for AI assistants
├── LICENSE                       # Apache License 2.0
├── CHANGELOG.md
└── CONTRIBUTING.md
```

### What Gets Installed

- Apache HTTP Server 2.4 (latest, from [apachelounge.com](https://www.apachelounge.com))
- Windows Service (named `Apache_<port>`, e.g. `Apache_80`)
- Windows Firewall inbound rule
- Registry entry under `HKLM\SOFTWARE\ApacheInstaller\Instances`
- Custom `index.html` with server info and link to install log

### Configuration

The installer writes a minimal secure `httpd.conf`:

- `Listen <port>` — binds to all interfaces on the selected port
- `mod_authz_host` — required for `Require ip` in server-status
- `Header always set X-*` — basic security headers
- `TraceEnable Off` — XST protection
- `ServerTokens Prod` — hides version info
- `/server-status` accessible from `127.0.0.1` only

### Attribution

If you use or distribute this tool, you must include a link to the original project per the Apache License 2.0:

```
Apache Installer for Windows — https://imiron.ru
https://github.com/imiron-ru/apache-installer
```

---

## Русский

### Возможности

- ✅ Автоопределение разрядности ОС (x86 / x64)
- ✅ Проверка и автоустановка Visual C++ Redistributable
- ✅ Несколько экземпляров Apache на разных портах
- ✅ Реестр экземпляров через Windows Registry (не зависит от расположения скрипта)
- ✅ Автоматический бэкап (только conf или папка целиком) перед переустановкой/удалением
- ✅ Проверка места на диске перед установкой и бэкапом
- ✅ Управление правилами брандмауэра Windows (без всплывающего окна)
- ✅ Полное логирование всех операций с временными метками
- ✅ Совместим с [ps2exe](https://github.com/MScholtes/PS2EXE) — компиляция в `.exe`
- ✅ **Единый скрипт** с автоопределением языка (en / ru), ручная установка через `-Lang en|ru`

### Требования

| Требование | Детали |
|---|---|
| ОС | Windows 7 SP1 или новее |
| PowerShell | 5.1 или новее |
| Права | Администратор |
| Сеть | Доступ в интернет (для скачивания Apache) |

### Быстрый старт

**Вариант A — запуск скомпилированного exe (рекомендуется):**
```
install-apache.exe
```

**Вариант B — PowerShell напрямую:**
```powershell
powershell -ExecutionPolicy Bypass -File src\install-apache.ps1
```

**Вариант C — принудительный выбор языка:**
```powershell
powershell -ExecutionPolicy Bypass -File src\install-apache.ps1 -Lang ru
```

### Сборка EXE

Запустите `build-exe.bat` — он установит ps2exe если нужно и скомпилирует скрипт:
```
build-exe.bat
```

Или вручную:
```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force
Import-Module ps2exe
Invoke-ps2exe .\src\install-apache.ps1 .\install-apache.exe -requireAdmin -noConsole:$false
```

> Ночные сборки производятся автоматически через GitHub Actions (`.github/workflows/nightly-build.yml`)  
> и публикуются как артефакты релиза при изменениях в репозитории.

### Структура репозитория

```
apache-installer/
├── src/
│   └── install-apache.ps1       # Многоязычный установщик (en + ru)
├── archive/                     # Устаревшие раздельные версии
│   ├── install-apache-en.ps1
│   ├── install-apache-ru.ps1
│   ├── install-en.bat
│   └── install-ru.bat
├── .github/
│   └── workflows/
│       └── nightly-build.yml    # Ночная сборка EXE через ps2exe
├── screenshots/                  # Скриншоты
├── build-exe.bat                 # Компиляция в exe через ps2exe
├── README.md
├── CLAUDE.md                     # Руководство по проекту для ИИ-ассистентов
├── LICENSE                       # Apache License 2.0
├── CHANGELOG.md
└── CONTRIBUTING.md
```

### Что устанавливается

- Apache HTTP Server 2.4 (актуальная версия с [apachelounge.com](https://www.apachelounge.com))
- Служба Windows (имя `Apache_<порт>`, например `Apache_80`)
- Правило брандмауэра Windows (входящее)
- Запись в реестре `HKLM\SOFTWARE\ApacheInstaller\Instances`
- Кастомный `index.html` с информацией о сервере и ссылкой на лог установки

### Указание авторства

При использовании или распространении инструмента необходимо указать ссылку на оригинальный проект согласно Apache License 2.0:

```
Apache Installer for Windows — https://imiron.ru
https://github.com/imiron-ru/apache-installer
```

---

## License

```
Copyright (c) 2026 imiron.ru

Licensed under the Apache License, Version 2.0.
You may not use this file except in compliance with the License.
See LICENSE file for details.
```
