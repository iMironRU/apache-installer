# Apache HTTP Server Installer for Windows

> Automated installer for Apache HTTP Server 2.4 on Windows.  
> Supports multiple instances, backups, firewall management and ps2exe compilation.

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
- ✅ Two languages: English (`-en`) and Russian (`-ru`)

### Requirements

| Requirement | Details |
|---|---|
| OS | Windows 7 SP1 or newer |
| PowerShell | 5.1 or newer |
| Rights | Administrator |
| Network | Internet access (to download Apache) |

### Quick Start

**Option A — Run PowerShell script directly:**
```
install-en.bat
```

**Option B — Run compiled exe (if available):**
```
install-apache-en.exe
```

**Option C — PowerShell directly:**
```powershell
powershell -ExecutionPolicy Bypass -File src\install-apache-en.ps1
```

### Build EXE

Run `build-exe.bat` — it will install ps2exe if needed and compile both language versions:
```
build-exe.bat
```

Or manually:
```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force
Import-Module ps2exe
Invoke-ps2exe .\src\install-apache-en.ps1 .\install-apache-en.exe -requireAdmin -noConsole:$false
```

### Repository Structure

```
apache-installer/
├── src/
│   ├── install-apache-en.ps1   # English version
│   └── install-apache-ru.ps1   # Russian version
├── screenshots/                 # Demo screenshots
├── install-en.bat               # Launch English version
├── install-ru.bat               # Launch Russian version
├── build-exe.bat                # Compile to exe via ps2exe
├── README.md
├── LICENSE                      # Apache License 2.0
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
- ✅ Два языка: английский (`-en`) и русский (`-ru`)

### Требования

| Требование | Детали |
|---|---|
| ОС | Windows 7 SP1 или новее |
| PowerShell | 5.1 или новее |
| Права | Администратор |
| Сеть | Доступ в интернет (для скачивания Apache) |

### Быстрый старт

**Вариант A — запуск через bat:**
```
install-ru.bat
```

**Вариант B — запущенный exe (если скомпилирован):**
```
install-apache-ru.exe
```

**Вариант C — PowerShell напрямую:**
```powershell
powershell -ExecutionPolicy Bypass -File src\install-apache-ru.ps1
```

### Сборка EXE

Запустите `build-exe.bat` — он установит ps2exe если нужно и скомпилирует обе языковые версии:
```
build-exe.bat
```

Или вручную:
```powershell
Install-Module -Name ps2exe -Scope CurrentUser -Force
Import-Module ps2exe
Invoke-ps2exe .\src\install-apache-ru.ps1 .\install-apache-ru.exe -requireAdmin -noConsole:$false
```

### Структура репозитория

```
apache-installer/
├── src/
│   ├── install-apache-en.ps1   # Английская версия
│   └── install-apache-ru.ps1   # Русская версия
├── screenshots/                 # Скриншоты
├── install-en.bat               # Запуск английской версии
├── install-ru.bat               # Запуск русской версии
├── build-exe.bat                # Компиляция в exe через ps2exe
├── README.md
├── LICENSE                      # Apache License 2.0
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
