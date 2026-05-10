<#
.SYNOPSIS
    Apache HTTP Server 2.4 — Windows Installer
.DESCRIPTION
    Automated installer for Apache HTTP Server on Windows.
    Supports multiple instances on different ports.
    Compatible with ps2exe compilation to standalone .exe

    Features:
    - Auto-detects OS architecture (x86/x64)
    - Checks Visual C++ Redistributable
    - Multiple Apache instances support
    - Automatic backup before reinstall/remove
    - Windows Firewall rule management
    - Instance registry via Windows Registry (HKLM)
    - Full logging of all operations

.NOTES
    Copyright (c) 2026 imiron.ru
    Licensed under the Apache License 2.0
    https://github.com/imiron-ru/apache-installer

    Requires: Windows 7+, PowerShell 5.1+, Administrator rights
    Compile:  Invoke-ps2exe .\install-apache-en.ps1 .\install-apache-en.exe -requireAdmin -noConsole:$false
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -----------------------------------------------
#  Admin check (runtime, works in exe too)
# -----------------------------------------------
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "  ! Run this script as Administrator." -ForegroundColor Red
    exit 1
}

# -----------------------------------------------
#  Working directory — ps1 folder OR exe folder
#  MyInvocation.MyCommand.Path is NULL inside exe,
#  so we use Process.MainModule.FileName instead.
# -----------------------------------------------
$exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$isExe   = $exePath -notmatch 'powershell|pwsh'

$WORK_DIR = if ($isExe) {
    Split-Path -Parent $exePath
} elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $PWD.Path
}

# -----------------------------------------------
#  Constants
# -----------------------------------------------
$INDEX_URL_64    = 'https://app.imiron.ru/apache/?arch=64'
$INDEX_URL_32    = 'https://app.imiron.ru/apache/?arch=32'
$VCREDIST_URL_64 = 'https://aka.ms/vc14/vc_redist.x64.exe'
$VCREDIST_URL_32 = 'https://aka.ms/vc14/vc_redist.x86.exe'
$VCREDIST_MIN    = [Version]'14.40.0.0'
$TEMP_ZIP        = Join-Path $env:TEMP 'apache-install.zip'
$TEMP_EXTRACT    = Join-Path $env:TEMP 'apache-extract'
$MIN_INSTALL_MB  = 80
$MIN_BACKUP_MB   = 50

$LOG_FILE = Join-Path $WORK_DIR ("install-apache-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")

# -----------------------------------------------
#  Logging
# -----------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $LOG_FILE -Value "[$ts] [$Level] $Message" -Encoding UTF8
}

trap {
    $errMsg  = $_.Exception.Message
    $errLine = $_.InvocationInfo.ScriptLineNumber
    Write-Log "EXCEPTION line $errLine : $errMsg" 'ERROR'
    Write-Log "Stack: $($_.ScriptStackTrace)" 'ERROR'
    Write-Fail "Error at line $errLine : $errMsg"
    Write-Fail "Log: $LOG_FILE"
    exit 1
}

# -----------------------------------------------
#  Output helpers
# -----------------------------------------------
function Write-Header([string]$Text) {
    Write-Host ""
    Write-Host "  ==========================================" -ForegroundColor DarkCyan
    Write-Host "    $Text" -ForegroundColor Cyan
    Write-Host "  ==========================================" -ForegroundColor DarkCyan
    Write-Log "=== $Text ===" 'INFO'
}
function Write-Step([string]$Text) { Write-Host "  > $Text" -ForegroundColor White;  Write-Log "> $Text" 'INFO'  }
function Write-OK([string]$Text)   { Write-Host "  + $Text" -ForegroundColor Green;  Write-Log "+ $Text" 'OK'    }
function Write-Warn([string]$Text) { Write-Host "  ~ $Text" -ForegroundColor Yellow; Write-Log "~ $Text" 'WARN'  }
function Write-Fail([string]$Text) { Write-Host "  ! $Text" -ForegroundColor Red;    Write-Log "! $Text" 'ERROR' }

function Confirm-Action([string]$Prompt) {
    $a = (Read-Host "  $Prompt (D/Y - yes, N - no)").Trim().ToUpper()
    Write-Log "Prompt: $Prompt | Answer: $a" 'INPUT'
    return ($a -eq "Д" -or $a -eq "Y" -or $a -eq "D")
}

function Read-Choice {
    param([string]$Prompt, [string]$Default = '')
    $hint   = if ($Default -ne '') { " [$Default]" } else { '' }
    $answer = (Read-Host "  $Prompt$hint").Trim()
    if ([string]::IsNullOrWhiteSpace($answer) -and $Default -ne '') { $answer = $Default }
    return $answer
}

# -----------------------------------------------
#  Instance registry — Windows Registry (HKLM)
#  Key: HKLM:\SOFTWARE\ApacheInstaller\Instances\<ServiceName>
#  Values: InstallDir, Port, InstalledAt
#  No JSON file needed — survives relocation of the script/exe.
# -----------------------------------------------
$REG_ROOT = 'HKLM:\SOFTWARE\ApacheInstaller\Instances'

function Get-RegInstances {
    if (-not (Test-Path $REG_ROOT)) { return @() }
    $result = @()
    foreach ($key in Get-ChildItem $REG_ROOT -ErrorAction SilentlyContinue) {
        try {
            $props = Get-ItemProperty $key.PSPath -ErrorAction Stop
            $result += [PSCustomObject]@{
                ServiceName = $key.PSChildName
                InstallDir  = $props.InstallDir
                Port        = $props.Port
                InstalledAt = $props.InstalledAt
            }
        } catch {}
    }
    return $result
}

function Save-RegInstance([string]$ServiceName, [string]$InstallDir, [string]$Port) {
    $keyPath = "$REG_ROOT\$ServiceName"
    if (-not (Test-Path $keyPath)) { New-Item -Path $keyPath -Force | Out-Null }
    Set-ItemProperty -Path $keyPath -Name InstallDir  -Value $InstallDir
    Set-ItemProperty -Path $keyPath -Name Port        -Value $Port
    Set-ItemProperty -Path $keyPath -Name InstalledAt -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-Log "Registry: saved $ServiceName -> $InstallDir port $Port" 'OK'
}

function Remove-RegInstance([string]$ServiceName) {
    $keyPath = "$REG_ROOT\$ServiceName"
    if (Test-Path $keyPath) {
        Remove-Item -Path $keyPath -Force -ErrorAction SilentlyContinue
        Write-Log "Registry: removed $ServiceName" 'INFO'
    }
}

# -----------------------------------------------
#  Discover all installed Apache instances
#  Sources: 1) our registry key  2) SCM scan
# -----------------------------------------------
function Get-InstalledApaches {
    $result = [System.Collections.Generic.List[object]]::new()
    $seen   = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    # From our registry
    foreach ($inst in Get-RegInstances) {
        $svc = Get-Service -Name $inst.ServiceName -ErrorAction SilentlyContinue
        $null = $seen.Add($inst.ServiceName)
        $result.Add([PSCustomObject]@{
            ServiceName = $inst.ServiceName
            InstallDir  = $inst.InstallDir
            Port        = $inst.Port
            Status      = if ($svc) { $svc.Status } else { "NotFound" }
            Source      = "registry"
        })
    }

    # SCM scan — catch instances not in our registry
    $apacheSvcs = @(Get-WmiObject Win32_Service -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'Apache*' -or $_.DisplayName -like 'Apache*' })

    foreach ($svc in $apacheSvcs) {
        if ($seen.Contains($svc.Name)) { continue }
        $null = $seen.Add($svc.Name)

        $binPath   = $svc.PathName -replace '"','' -replace '\s+-k.*$',''
        $installDir = if ($binPath) { Split-Path (Split-Path $binPath -Parent) -Parent } else { "unknown" }

        # Try to read port from httpd.conf
        $port = "?"
        $confPath = Join-Path $installDir "conf\httpd.conf"
        if (Test-Path $confPath) {
            $listenLine = Select-String -Path $confPath -Pattern '^\s*Listen\s+(\d+)' |
                          Select-Object -First 1
            if ($listenLine) { $port = $listenLine.Matches[0].Groups[1].Value }
        }

        $result.Add([PSCustomObject]@{
            ServiceName = $svc.Name
            InstallDir  = $installDir
            Port        = $port
            Status      = $svc.State
            Source      = "scm"
        })
    }

    return $result.ToArray()
}

# -----------------------------------------------
#  VC++ Redistributable check
# -----------------------------------------------
function Get-VCRedistVersion([int]$Bits) {
    $arch    = if ($Bits -eq 64) { 'x64' } else { 'x86' }
    $keys    = @(
        "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\$arch",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\$arch"
    )
    $bestVer = $null
    foreach ($key in $keys) {
        if (-not (Test-Path $key)) { continue }
        try {
            $p = Get-ItemProperty $key -ErrorAction Stop
            $verStr = if ($p.Version) { $p.Version }
                      elseif ($p.Major) { "$($p.Major).$($p.Minor).$($p.Bld).$($p.Rbld)" }
                      else { $null }
            if ($verStr) {
                $ver = [Version]($verStr.TrimStart('v'))
                if (-not $bestVer -or $ver -gt $bestVer) { $bestVer = $ver }
            }
        } catch {}
    }
    return $bestVer
}

function Assert-VCRedist([int]$Bits) {
    Write-Step "Checking Visual C++ Redistributable ($Bits-bit)..."
    Write-Log "VC++ Redist check: $Bits-bit, min $VCREDIST_MIN" 'INFO'

    $installed = Get-VCRedistVersion -Bits $Bits
    Write-Log "VC++ Redist found: $installed" 'INFO'

    if ($installed -and $installed -ge $VCREDIST_MIN) {
        Write-OK "Visual C++ Redistributable $installed — OK"
        return
    }

    if ($installed) {
        Write-Warn "Outdated VC++ Redistributable: $installed (need $VCREDIST_MIN)"
    } else {
        Write-Warn "Visual C++ Redistributable ($Bits-bit) not found!"
        Write-Warn "Apache will not start without it."
    }

    Write-Host ""
    Write-Host "  Options:" -ForegroundColor Cyan
    Write-Host "    [1] Download and install automatically (recommended)"
    Write-Host "    [2] Open download page (install manually)"
    Write-Host "    [3] Skip (Apache may not start)"
    Write-Host ""

    $vc = Read-Choice -Prompt "Your choice (1-3)" -Default "1"
    Write-Log "VC++ choice: $vc" 'INPUT'

    if ($vc -eq '3') {
        Write-Warn "VC++ Redistributable skipped."
        return
    }

    $vcUrl  = if ($Bits -eq 64) { $VCREDIST_URL_64 } else { $VCREDIST_URL_32 }
    $vcArch = if ($Bits -eq 64) { 'x64' } else { 'x86' }

    if ($vc -eq '2') {
        Start-Process "https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist"
        Write-Host "  Install VC++ Redistributable and press Enter to continue..." -ForegroundColor Yellow
        $null = Read-Host
        return
    }

    $vcTemp = Join-Path $env:TEMP "vc_redist_$vcArch.exe"
    Write-Step "Downloading VC++ Redistributable ($vcArch)..."
    Write-Log "Downloading: $vcUrl" 'INFO'
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $vcUrl -OutFile $vcTemp -UseBasicParsing
    } catch {
        Write-Warn "Download failed: $($_.Exception.Message)"
        return
    }

    Write-Step "Installing VC++ Redistributable (silent)..."
    try {
        $p = Start-Process -FilePath $vcTemp -ArgumentList '/install','/quiet','/norestart' -Wait -PassThru
        Write-Log "VC++ ExitCode: $($p.ExitCode)" 'INFO'
        if ($p.ExitCode -eq 0)    { Write-OK "VC++ Redistributable installed." }
        elseif ($p.ExitCode -eq 3010) { Write-OK "VC++ installed. Reboot required."; Write-Warn "Please reboot before starting Apache." }
        else  { Write-Warn "VC++ installer returned code $($p.ExitCode)." }
    } catch {
        Write-Warn "Installation error: $($_.Exception.Message)"
    } finally {
        Remove-Item $vcTemp -Force -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------
#  Disk space
# -----------------------------------------------
function Get-FreeDiskSpaceMB([string]$Path) {
    $letter = [System.IO.Path]::GetPathRoot($Path).TrimEnd('\').TrimEnd(':')
    $drive  = Get-PSDrive -Name $letter -ErrorAction SilentlyContinue
    if ($drive) { return [math]::Round($drive.Free / 1MB) }
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='${letter}:'" -ErrorAction SilentlyContinue
    if ($disk) { return [math]::Round($disk.FreeSpace / 1MB) }
    return 999999
}

function Assert-DiskSpace([string]$Path, [int]$RequiredMB, [string]$Purpose) {
    $free = Get-FreeDiskSpaceMB -Path $Path
    Write-Log "Disk $Path : $free MB free, need $RequiredMB MB ($Purpose)" 'INFO'
    if ($free -lt $RequiredMB) {
        throw "Not enough disk space for $Purpose. Free: $free MB, need: $RequiredMB MB."
    }
    Write-OK "Disk space OK: $free MB free (need $RequiredMB MB)"
}

# -----------------------------------------------
#  Port check
# -----------------------------------------------
function Test-PortBusy([string]$Port) {
    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        return (@(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue).Count -gt 0)
    }
    return (@(netstat -ano | Select-String ":$Port\s" | Where-Object { $_ -match 'LISTENING' }).Count -gt 0)
}

function Get-PortOwner([string]$Port) {
    $pid_ = $null
    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
                Select-Object -First 1
        if ($conn) { $pid_ = $conn.OwningProcess }
    } else {
        $lines = @(netstat -ano | Select-String ":$Port\s" | Where-Object { $_ -match 'LISTENING' })
        if ($lines.Count -gt 0) {
            $pid_ = ($lines[0] -as [string]).Trim() -split '\s+' | Select-Object -Last 1
        }
    }
    if (-not $pid_) { return "unknown" }
    try {
        $proc    = Get-Process -Id $pid_ -ErrorAction Stop
        $exePath = try { $proc.MainModule.FileName } catch { '' }
        return "$($proc.ProcessName) (PID: $pid_)$(if ($exePath) { " — $exePath" })"
    } catch { return "PID: $pid_" }
}

# -----------------------------------------------
#  Windows Service helpers
# -----------------------------------------------
function Test-ServiceExists([string]$Name) {
    return ($null -ne (Get-Service -Name $Name -ErrorAction SilentlyContinue))
}
function Test-ServiceRunning([string]$Name) {
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    return ($null -ne $svc -and $svc.Status -eq "Running")
}
function Stop-NamedService([string]$Name) {
    if (-not (Test-ServiceExists $Name)) { return }
    Write-Step "Stopping service $Name..."
    try { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 } catch {}
}
function Remove-NamedService([string]$Name) {
    if (-not (Test-ServiceExists $Name)) { return }
    Stop-NamedService -Name $Name
    Write-Step "Removing service $Name..."
    sc.exe delete $Name 2>&1 | Out-Null
    Start-Sleep -Seconds 1
    Write-OK "Service $Name removed."
}

# -----------------------------------------------
#  Firewall
# -----------------------------------------------
function Add-ApacheFirewallRule([string]$RuleName, [string]$HttpdExe, [string]$Port) {
    Write-Step "Adding firewall rule ($RuleName, port $Port)..."
    Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
    try {
        New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Program $HttpdExe `
            -Action Allow -Protocol TCP -LocalPort $Port -Profile Any | Out-Null
        Write-OK "Firewall rule added."
        Write-Log "Firewall: $RuleName added" 'OK'
    } catch {
        Write-Warn "Firewall rule error: $($_.Exception.Message)"
    }
}
function Remove-ApacheFirewallRule([string]$RuleName) {
    Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
    Write-Log "Firewall: $RuleName removed" 'INFO'
}

# -----------------------------------------------
#  Cleanup on error
# -----------------------------------------------
function Invoke-Cleanup([string]$InstallDir, [string]$ServiceName, [string]$FwRule) {
    Write-Warn "Cleaning up after error..."
    Remove-NamedService -Name $ServiceName
    Remove-ApacheFirewallRule -RuleName $FwRule
    Remove-RegInstance -ServiceName $ServiceName
    if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue }
    foreach ($tmp in @($TEMP_ZIP, $TEMP_EXTRACT)) {
        if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# -----------------------------------------------
#  Backup
# -----------------------------------------------
function Backup-Install([string]$InstallDir) {
    if (-not (Test-Path $InstallDir)) { return $null }

    Write-Host ""
    Write-Host "  Backup options:" -ForegroundColor Cyan
    Write-Host "    [1] Config only (conf\)  ~1 MB, fast"
    Write-Host "    [2] Full folder"
    Write-Host "    [3] Both"
    Write-Host "    [4] Skip backup"
    Write-Host ""

    $bc = Read-Choice -Prompt "Your choice (1-4)" -Default "1"
    Write-Log "Backup choice: $bc" 'INPUT'
    if ($bc -eq '4') { Write-Warn "Backup skipped."; return $null }

    $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
    $result = $null

    if ($bc -eq '1' -or $bc -eq '3') {
        $dst = Join-Path $WORK_DIR "backup-$ts-conf.zip"
        $src = "$InstallDir\conf"
        if (Test-Path $src) {
            $szMB = [math]::Round((Get-ChildItem $src -Recurse |
                Measure-Object -Property Length -Sum).Sum / 1MB + 1)
            if ((Get-FreeDiskSpaceMB $WORK_DIR) -ge $szMB) {
                try {
                    Write-Step "Archiving config -> $dst"
                    Compress-Archive -Path "$src\*" -DestinationPath $dst -Force
                    $zipMB = [math]::Round((Get-Item $dst).Length / 1MB, 2)
                    Write-OK "Config backup: $dst ($zipMB MB)"
                    Write-Log "Backup conf: $zipMB MB" 'OK'
                    $result = $dst
                } catch { Write-Warn "Config backup error: $($_.Exception.Message)" }
            } else { Write-Warn "Not enough space for config backup." }
        }
    }

    if ($bc -eq '2' -or $bc -eq '3') {
        $dst = Join-Path $WORK_DIR "backup-$ts-full.zip"
        $szMB = [math]::Round((Get-ChildItem $InstallDir -Recurse -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum / 1MB + 5)
        if ((Get-FreeDiskSpaceMB $WORK_DIR) -ge ($szMB + 10)) {
            try {
                Write-Step "Archiving full folder -> $dst"
                Compress-Archive -Path "$InstallDir\*" -DestinationPath $dst -Force
                $zipMB = [math]::Round((Get-Item $dst).Length / 1MB, 1)
                Write-OK "Full backup: $dst ($zipMB MB)"
                Write-Log "Backup full: $zipMB MB" 'OK'
                if (-not $result) { $result = $dst }
            } catch { Write-Warn "Full backup error: $($_.Exception.Message)" }
        } else { Write-Warn "Not enough space for full backup." }
    }

    return $result
}

# -----------------------------------------------
#  Instance name helpers
# -----------------------------------------------
function Get-ServiceName([string]$Port) { return "Apache_$Port" }
function Get-FwRuleName([string]$Port)  { return "Apache HTTP (port $Port)" }

# -----------------------------------------------
#  Install dir menu
# -----------------------------------------------
function Select-InstallDir {
    $options = @('C:\Apache24', 'D:\Apache24', 'C:\Apache')
    while ($true) {
        Write-Host ""
        Write-Host "  Select installation folder:" -ForegroundColor Cyan
        Write-Host ""
        for ($i = 0; $i -lt $options.Count; $i++) {
            $mark = if (Test-Path $options[$i]) { " [exists]" } else { "" }
            Write-Host "    [$($i+1)] $($options[$i])$mark"
        }
        Write-Host "    [$($options.Count+1)] Enter custom path"
        Write-Host ""

        $choice = Read-Choice -Prompt "Your choice (1-$($options.Count+1))" -Default "1"
        Write-Log "Folder choice: $choice" 'INPUT'

        $selected = $null
        if ($choice -match '^\d+$') {
            $idx = [int]$choice
            if ($idx -ge 1 -and $idx -le $options.Count) { $selected = $options[$idx - 1] }
            elseif ($idx -eq $options.Count + 1) {
                $custom = (Read-Host "  Enter full path (e.g. C:\MyApache)").Trim()
                if ([string]::IsNullOrEmpty($custom)) { Write-Warn "Path cannot be empty."; continue }
                if ($custom -match ' ') { Write-Warn "Path must not contain spaces."; continue }
                $selected = $custom
            }
        }
        if (-not $selected) { Write-Warn "Invalid choice."; continue }

        # Check if already used by another instance
        $existing = Get-RegInstances | Where-Object { $_.InstallDir -eq $selected }
        if ($existing) {
            Write-Warn "This folder is used by instance $($existing.ServiceName) (port $($existing.Port))."
            if (Confirm-Action "Reinstall this instance?") { return $selected }
            continue
        }

        if (Test-Path $selected) {
            Write-Warn "Folder $selected already exists."
            if (Confirm-Action "Use this folder? (backup will be offered)") { return $selected }
            continue
        }

        return $selected
    }
}

# -----------------------------------------------
#  Port menu
# -----------------------------------------------
function Select-Port {
    $ports     = @('80', '8080', '8000', '8888')
    $usedPorts = @(Get-RegInstances | ForEach-Object { $_.Port })

    while ($true) {
        Write-Host ""
        Write-Host "  Select port for Apache:" -ForegroundColor Cyan
        Write-Host ""
        for ($i = 0; $i -lt $ports.Count; $i++) {
            $p = $ports[$i]
            if ($usedPorts -contains $p) {
                $inst = Get-RegInstances | Where-Object { $_.Port -eq $p } | Select-Object -First 1
                Write-Host "    [$($i+1)] $p [used by $($inst.ServiceName)]" -ForegroundColor DarkYellow
            } elseif (Test-PortBusy $p) {
                Write-Host "    [$($i+1)] $p [BUSY: $(Get-PortOwner $p)]" -ForegroundColor Yellow
            } else {
                Write-Host "    [$($i+1)] $p [free]"
            }
        }
        Write-Host "    [$($ports.Count+1)] Enter custom port"
        Write-Host ""

        $choice = Read-Choice -Prompt "Your choice (1-$($ports.Count+1))" -Default "1"
        Write-Log "Port choice: $choice" 'INPUT'

        $selected = $null
        if ($choice -match '^\d+$') {
            $idx = [int]$choice
            if ($idx -ge 1 -and $idx -le $ports.Count) { $selected = $ports[$idx - 1] }
            elseif ($idx -eq $ports.Count + 1) {
                $custom = (Read-Host "  Enter port (1024-65535)").Trim()
                if ($custom -notmatch '^\d+$' -or [int]$custom -lt 1024 -or [int]$custom -gt 65535) {
                    Write-Warn "Port must be a number between 1024-65535."; continue
                }
                $selected = $custom
            }
        }
        if (-not $selected) { Write-Warn "Invalid choice."; continue }

        if ($usedPorts -contains $selected) {
            $inst = Get-RegInstances | Where-Object { $_.Port -eq $selected } | Select-Object -First 1
            Write-Warn "Port $selected is used by $($inst.ServiceName) in $($inst.InstallDir)."
            if (-not (Confirm-Action "Use this port anyway?")) { continue }
        }

        if (Test-PortBusy $selected) {
            Write-Warn "Port $selected is busy: $(Get-PortOwner $selected)"
            if (-not (Confirm-Action "Use this port anyway?")) { continue }
            Write-Log "Port $selected selected despite being busy" 'WARN'
        }

        return $selected
    }
}

# -----------------------------------------------
#  Download helpers
# -----------------------------------------------
function Get-DistribUrl([int]$Bits) {
    $url = if ($Bits -eq 64) { $INDEX_URL_64 } else { $INDEX_URL_32 }
    Write-Step "Getting download URL ($Bits-bit)..."
    Write-Log "GET $url" 'INFO'
    try {
        $ProgressPreference = 'SilentlyContinue'
        $link = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15).Content.Trim()
        Write-Log "Server response: $link" 'INFO'
    } catch { throw "Failed to get URL: $($_.Exception.Message)" }
    if ($link -notmatch '^https?://.+\.zip$') { throw "Unexpected server response: $link" }
    Write-OK "Distribution: $(Split-Path $link -Leaf)"
    return $link
}

function Download-Distrib([string]$Url, [string]$OutFile) {
    Write-Step "Downloading..."
    Write-Log "Download: $Url" 'INFO'
    $done = $false
    if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
        try {
            Start-BitsTransfer -Source $Url -Destination $OutFile -DisplayName 'Apache HTTP Server'
            $done = $true
        } catch {
            Write-Warn "BITS failed, switching to WebRequest"
        }
    }
    if (-not $done) {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
    }
    if (-not (Test-Path $OutFile)) { throw "File not saved: $OutFile" }
    $sizeMB = [math]::Round((Get-Item $OutFile).Length / 1MB, 1)
    Write-OK "Downloaded $sizeMB MB"
}

# -----------------------------------------------
#  httpd.conf generator
# -----------------------------------------------
function New-HttpdConf([string]$InstallDir, [string]$Port, [string]$ServiceName) {
    $srvRoot = $InstallDir.Replace('\', '/')
    return @"
# Apache httpd 2.4 — instance $ServiceName
# Port: $Port | Dir: $InstallDir
# Generated by install-apache

Define         SRVROOT  "$srvRoot"
Define         SRVPORT  "$Port"
Define         SRVNAME  "localhost"

ServerRoot     "`${SRVROOT}"
ServerName     `${SRVNAME}:`${SRVPORT}
Listen         `${SRVPORT}

ServerTokens   Prod
ServerSignature Off
TraceEnable    Off
ServerAdmin    webadmin@localhost

LoadModule alias_module        modules/mod_alias.so
LoadModule authz_core_module   modules/mod_authz_core.so
LoadModule authz_host_module   modules/mod_authz_host.so
LoadModule dir_module          modules/mod_dir.so
LoadModule headers_module      modules/mod_headers.so
LoadModule log_config_module   modules/mod_log_config.so
LoadModule mime_module         modules/mod_mime.so
LoadModule status_module       modules/mod_status.so

TypesConfig    conf/mime.types
PidFile        logs/httpd.pid
DirectoryIndex index.html

ErrorLog       logs/error_log
LogFormat      "%h %l %u %t \"%r\" %>s %b" common
CustomLog      logs/access_log common

AcceptFilter   http   none
AcceptFilter   https  none
EnableSendfile off
EnableMMAP     off

KeepAlive        On
KeepAliveTimeout 30
HostnameLookups  Off

Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options        "SAMEORIGIN"
Header always set X-XSS-Protection       "1; mode=block"

DocumentRoot "`${SRVROOT}/htdocs"

<Directory />
    AllowOverride none
    Require all denied
</Directory>

<Directory "`${SRVROOT}/htdocs">
    Require all granted
    AllowOverride none
    Options -Indexes -FollowSymLinks
</Directory>

<Location /server-status>
    SetHandler server-status
    Require ip 127.0.0.1 ::1
</Location>
"@
}

# -----------------------------------------------
#  index.html generator
# -----------------------------------------------
function New-IndexHtml([string]$InstallDir, [string]$Port, [string]$ServiceName, [string]$LogFile) {
    $addr    = if ($Port -eq '80') { 'http://localhost' } else { "http://localhost:$Port" }
    $logName = Split-Path $LogFile -Leaf
    $logPath = $LogFile.Replace('\', '/')
    return @"
<!DOCTYPE html><html lang="ru"><head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Apache $ServiceName</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#0f1117;
         color:#e2e8f0;min-height:100vh;display:flex;align-items:center;justify-content:center;}
    .card{background:#1a1d27;border:1px solid #2d3148;border-radius:16px;
          padding:48px 56px;max-width:520px;width:90%;text-align:center;}
    .icon{width:64px;height:64px;background:#22c55e18;border:1px solid #22c55e40;border-radius:50%;
          display:flex;align-items:center;justify-content:center;margin:0 auto 28px;font-size:28px;}
    h1{font-size:22px;font-weight:600;color:#f1f5f9;margin-bottom:6px;}
    .svc{font-size:13px;color:#475569;margin-bottom:24px;}
    .badge{display:inline-flex;align-items:center;gap:6px;background:#22c55e15;
           border:1px solid #22c55e35;color:#4ade80;font-size:13px;
           padding:6px 14px;border-radius:20px;margin-bottom:32px;}
    .dot{width:6px;height:6px;background:#22c55e;border-radius:50%;animation:pulse 2s infinite;}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
    .info{background:#12151f;border:1px solid #1e2235;border-radius:10px;padding:16px 20px;text-align:left;}
    .row{display:flex;justify-content:space-between;align-items:center;font-size:13px;
         padding:6px 0;border-bottom:1px solid #1e2235;}
    .row:last-child{border-bottom:none}
    .k{color:#475569;white-space:nowrap;margin-right:12px;}
    .v{color:#94a3b8;font-family:Consolas,monospace;word-break:break-all;text-align:right;}
    a{color:#6366f1;text-decoration:none;}a:hover{text-decoration:underline;}
    .log-link{margin-top:20px;font-size:12px;color:#334155;text-align:center;}
    .log-link a{color:#475569;}
  </style>
</head><body><div class="card">
  <div class="icon">&#10003;</div>
  <h1>Apache is running</h1>
  <p class="svc">Service: $ServiceName</p>
  <div class="badge"><div class="dot"></div>Active</div>
  <div class="info">
    <div class="row"><span class="k">Address</span><span class="v"><a href="$addr">$addr</a></span></div>
    <div class="row"><span class="k">Service</span><span class="v">$ServiceName</span></div>
    <div class="row"><span class="k">Directory</span><span class="v">$InstallDir\htdocs</span></div>
    <div class="row"><span class="k">Config</span><span class="v">$InstallDir\conf\httpd.conf</span></div>
    <div class="row"><span class="k">Apache logs</span><span class="v">$InstallDir\logs\</span></div>
    <div class="row"><span class="k">Status</span><span class="v"><a href="/server-status">server-status</a></span></div>
  </div>
  <div class="log-link">Install log: <a href="file:///$logPath">$logName</a></div>
</div></body></html>
"@
}

# ===============================================
#  MAIN
# ===============================================

Write-Log "==========================================" 'INFO'
Write-Log "Starting install-apache" 'INFO'
Write-Log "WorkDir: $WORK_DIR | IsExe: $isExe" 'INFO'
Write-Log "User: $env:USERNAME  Machine: $env:COMPUTERNAME" 'INFO'
Write-Log "PowerShell: $($PSVersionTable.PSVersion)" 'INFO'
Write-Log "==========================================" 'INFO'

Clear-Host
Write-Host ""
Write-Host "  +==========================================+" -ForegroundColor Cyan
Write-Host "  |   Apache HTTP Server Installer          |" -ForegroundColor Cyan
Write-Host "  |   localhost | Windows x86/x64           |" -ForegroundColor Cyan
Write-Host "  +==========================================+" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Log: $LOG_FILE" -ForegroundColor DarkGray

# Show installed instances
$currentInstances = @(Get-InstalledApaches)
if ($currentInstances.Count -gt 0) {
    Write-Host ""
    Write-Host "  Installed instances:" -ForegroundColor DarkCyan
    foreach ($inst in $currentInstances) {
        $addr = if ($inst.Port -eq '80') { 'http://localhost' } else { "http://localhost:$($inst.Port)" }
        Write-Host "    $($inst.ServiceName)  $addr  $($inst.InstallDir)  [$($inst.Status)]" -ForegroundColor DarkGray
    }
}

# Main menu
Write-Host ""
Write-Host "  Select action:" -ForegroundColor Cyan
Write-Host ""
Write-Host "    [1] Install new Apache instance"
if ($currentInstances.Count -gt 0) {
    Write-Host "    [2] Remove Apache instance"
} else {
    Write-Host "    [2] Remove Apache instance  [none installed]" -ForegroundColor DarkGray
}
Write-Host "    [3] Exit"
Write-Host ""

$validChoices = if ($currentInstances.Count -gt 0) { @('1','2','3') } else { @('1','3') }
$mainChoice = ''
while ($mainChoice -notin $validChoices) {
    $mainChoice = Read-Choice -Prompt "Your choice (1-3)" -Default "1"
    if ($mainChoice -notin $validChoices) {
        if ($mainChoice -eq '2') { Write-Warn "No installed instances to remove." }
        else { Write-Warn "Invalid choice." }
    }
}
Write-Log "Main menu: $mainChoice" 'INPUT'

if ($mainChoice -eq '3') { Write-Step "Exit."; exit 0 }

# ============================================================
#  REMOVE
# ============================================================
if ($mainChoice -eq '2') {
    Write-Header "Remove Apache Instance"

    $installed = @(Get-InstalledApaches)

    Write-Host ""
    Write-Host "  Select instance to remove:" -ForegroundColor Cyan
    Write-Host ""
    for ($i = 0; $i -lt $installed.Count; $i++) {
        $inst = $installed[$i]
        $addr = if ($inst.Port -eq '?') { "port $($inst.Port)" } `
                elseif ($inst.Port -eq '80') { 'http://localhost' } `
                else { "http://localhost:$($inst.Port)" }
        Write-Host "    [$($i+1)] $($inst.ServiceName)  $addr  $($inst.InstallDir)  [$($inst.Status)]"
    }
    Write-Host ""

    $dc = Read-Choice -Prompt "Your choice (1-$($installed.Count))" -Default "1"
    Write-Log "Remove choice: $dc" 'INPUT'

    if ($dc -notmatch '^\d+$' -or [int]$dc -lt 1 -or [int]$dc -gt $installed.Count) {
        Write-Warn "Invalid choice."; exit 1
    }

    $target = $installed[[int]$dc - 1]
    $fwRule = Get-FwRuleName -Port $target.Port

    Write-Host ""
    Write-Host "  Will be removed:" -ForegroundColor Yellow
    Write-Host "    Service : $($target.ServiceName)" -ForegroundColor Yellow
    Write-Host "    Folder  : $($target.InstallDir)"  -ForegroundColor Yellow
    Write-Host "    Port    : $($target.Port)"         -ForegroundColor Yellow
    Write-Host ""

    if (-not (Confirm-Action "Remove this instance?")) {
        Write-Step "Cancelled."; exit 0
    }

    # Backup before removal
    if (Test-Path $target.InstallDir) {
        $freeForBackup = Get-FreeDiskSpaceMB -Path $WORK_DIR
        if ($freeForBackup -lt $MIN_BACKUP_MB) {
            Write-Warn "Not enough space for backup ($freeForBackup MB)."
        } else {
            $backupResult = Backup-Install -InstallDir $target.InstallDir
            if ($backupResult) { Write-OK "Backup saved: $backupResult" }
        }
    }

    Remove-NamedService -Name $target.ServiceName
    Remove-ApacheFirewallRule -RuleName $fwRule
    Remove-RegInstance -ServiceName $target.ServiceName

    if (Test-Path $target.InstallDir) {
        Write-Step "Removing folder $($target.InstallDir)..."
        try {
            Remove-Item -Path $target.InstallDir -Recurse -Force
            Write-OK "Folder removed."
            Write-Log "Folder $($target.InstallDir) removed" 'OK'
        } catch {
            Write-Fail "Could not remove folder: $($_.Exception.Message)"
        }
    }

    Write-OK "Instance $($target.ServiceName) removed."
    Write-Log "Remove complete: $($target.ServiceName)" 'OK'
    Write-Log "==========================================" 'INFO'
    exit 0
}

# ============================================================
#  INSTALL
# ============================================================

# Step 1: OS bits
Write-Header "System Detection"
Write-Log "PROCESSOR_ARCHITECTURE: $env:PROCESSOR_ARCHITECTURE" 'INFO'
$osBits = if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') { 64 } else { 32 }
Write-OK "OS: Windows $osBits-bit"

# Step 2: VC++ check
Write-Header "Visual C++ Redistributable"
Assert-VCRedist -Bits $osBits

# Step 3: Folder
Write-Header "Installation Folder"
$installDir = Select-InstallDir
Write-OK "Folder: $installDir"

# Step 4: Port
Write-Header "Port"
$port        = Select-Port
$serviceName = Get-ServiceName -Port $port
$fwRuleName  = Get-FwRuleName  -Port $port
Write-OK "Port: $port  Service: $serviceName"

# Step 5: Confirm
Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host "  | Installation parameters                  |" -ForegroundColor Cyan
Write-Host "  |  Folder  : $installDir"
Write-Host "  |  Port    : $port"
Write-Host "  |  Service : $serviceName"
Write-Host "  |  OS      : Windows $osBits-bit"
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host ""
Write-Log "Params: service=$serviceName folder=$installDir port=$port os=$osBits-bit" 'INFO'

if (-not (Confirm-Action "Start installation?")) {
    Write-Step "Cancelled."
    exit 0
}

# Step 6: Disk space
Write-Header "Disk Space Check"
Assert-DiskSpace -Path $installDir -RequiredMB $MIN_INSTALL_MB -Purpose "Apache installation"
Assert-DiskSpace -Path $env:TEMP   -RequiredMB 30              -Purpose "temp archive"

# Step 7: Backup + remove old
Write-Header "Preparation"
$backupPath = $null

if (Test-Path $installDir) {
    $freeForBackup = Get-FreeDiskSpaceMB -Path $WORK_DIR
    if ($freeForBackup -lt $MIN_BACKUP_MB) {
        Write-Warn "Not enough space for backup ($freeForBackup MB)."
        if (-not (Confirm-Action "Continue without backup?")) { exit 0 }
    } else {
        $backupPath = Backup-Install -InstallDir $installDir
    }
    Remove-NamedService -Name $serviceName
    Write-Step "Removing $installDir..."
    Remove-Item -Path $installDir -Recurse -Force
    Write-OK "Old installation removed."
} else {
    Remove-NamedService -Name $serviceName
}

# Step 8: Download + extract
Write-Header "Download"
$distribUrl = Get-DistribUrl -Bits $osBits
Download-Distrib -Url $distribUrl -OutFile $TEMP_ZIP

Write-Header "Installation"
Write-Step "Extracting archive..."
if (Test-Path $TEMP_EXTRACT) { Remove-Item $TEMP_EXTRACT -Recurse -Force }

try {
    Expand-Archive -Path $TEMP_ZIP -DestinationPath $TEMP_EXTRACT -Force
} catch {
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "Extraction error: $($_.Exception.Message)"
}

# Find httpd.exe to locate the root
$httpdFound = Get-ChildItem -Path $TEMP_EXTRACT -Recurse -Filter 'httpd.exe' |
              Select-Object -First 1
if (-not $httpdFound) {
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "httpd.exe not found in archive. File may be corrupted."
}

$extracted = $httpdFound.Directory.Parent.FullName
Write-Log "Distribution root: $extracted" 'INFO'

try {
    Move-Item -Path $extracted -Destination $installDir -Force
} catch {
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "Move error: $($_.Exception.Message)"
}

Remove-Item $TEMP_ZIP     -Force -ErrorAction SilentlyContinue
Remove-Item $TEMP_EXTRACT -Recurse -Force -ErrorAction SilentlyContinue
Write-OK "Extracted to $installDir"

# Step 9: Config files
Write-Step "Writing httpd.conf..."
try {
    New-HttpdConf -InstallDir $installDir -Port $port -ServiceName $serviceName |
        Set-Content -Path "$installDir\conf\httpd.conf" -Encoding UTF8
    Write-OK "httpd.conf written."
} catch {
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "httpd.conf write error: $($_.Exception.Message)"
}

Write-Step "Writing index.html..."
try {
    New-IndexHtml -InstallDir $installDir -Port $port -ServiceName $serviceName -LogFile $LOG_FILE |
        Set-Content -Path "$installDir\htdocs\index.html" -Encoding UTF8
    Write-OK "index.html written."
} catch {
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "index.html write error: $($_.Exception.Message)"
}

# Step 10: Firewall rule (before service start — prevents Windows Security Alert popup)
Write-Header "Windows Firewall"
$httpdExe = "$installDir\bin\httpd.exe"
Add-ApacheFirewallRule -RuleName $fwRuleName -HttpdExe $httpdExe -Port $port

# Step 11: Register service
Write-Header "Windows Service"
Write-Step "Registering service $serviceName..."
Write-Log "Run: $httpdExe -k install -n $serviceName" 'INFO'

if (-not (Test-Path $httpdExe)) {
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "httpd.exe not found: $httpdExe"
}

$stdOut = Join-Path $env:TEMP 'httpd-stdout.txt'
$stdErr = Join-Path $env:TEMP 'httpd-stderr.txt'

$proc = Start-Process -FilePath $httpdExe -ArgumentList '-k','install','-n',$serviceName `
    -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdOut -RedirectStandardError $stdErr

$outTxt = if (Test-Path $stdOut) { Get-Content $stdOut -Raw } else { '' }
$errTxt = if (Test-Path $stdErr) { Get-Content $stdErr -Raw } else { '' }
Remove-Item $stdOut,$stdErr -Force -ErrorAction SilentlyContinue

Write-Log "httpd.exe stdout: $outTxt" 'INFO'
Write-Log "httpd.exe stderr: $errTxt" 'INFO'
Write-Log "httpd.exe ExitCode: $($proc.ExitCode)" 'INFO'

if ($proc.ExitCode -ne 0) {
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "httpd.exe failed with code $($proc.ExitCode).`nstderr: $errTxt"
}
if (-not (Test-ServiceExists $serviceName)) {
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "Service $serviceName not found in SCM after registration."
}
Write-OK "Service $serviceName registered."

Write-Step "Starting service..."
try {
    Start-Service -Name $serviceName
    Start-Sleep -Seconds 3
} catch {
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "Could not start service: $($_.Exception.Message)"
}

if (-not (Test-ServiceRunning $serviceName)) {
    $apacheErr = if (Test-Path "$installDir\logs\error_log") {
        Get-Content "$installDir\logs\error_log" -Tail 15 | Out-String
    } else { "(not found)" }
    Write-Log "Service did not start. error_log:`n$apacheErr" 'ERROR'
    Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
    throw "Service $serviceName did not start.`nerror_log:`n$apacheErr"
}
Write-OK "Service $serviceName started."

# Save to Windows registry
Save-RegInstance -ServiceName $serviceName -InstallDir $installDir -Port $port

# Step 12: HTTP check
Write-Header "Verification"
$checkUrl = if ($port -eq '80') { 'http://localhost' } else { "http://localhost:$port" }
Write-Step "GET $checkUrl ..."
Start-Sleep -Seconds 1

$statusCode = 0
try {
    $ProgressPreference = 'SilentlyContinue'
    $statusCode = (Invoke-WebRequest -Uri $checkUrl -UseBasicParsing -TimeoutSec 10).StatusCode
    Write-Log "HTTP response: $statusCode" 'INFO'
} catch { Write-Log "HTTP check: $($_.Exception.Message)" 'WARN' }

if ($statusCode -eq 200) {
    Write-OK "Server responded HTTP 200 — works!"
    Write-Log "HTTP check: SUCCESS" 'OK'
} else {
    Write-Warn "Response: $statusCode. Check: $installDir\logs\error_log"
}

# Step 13: Summary
Write-Header "Done!"
Write-Host ""
Write-Host "  Address : $checkUrl"      -ForegroundColor Green
Write-Host "  Service : $serviceName"   -ForegroundColor Green
Write-Host "  Folder  : $installDir"    -ForegroundColor Green
Write-Host "  Log     : $LOG_FILE"      -ForegroundColor DarkGray
if ($backupPath) { Write-Host "  Backup  : $backupPath" -ForegroundColor DarkGray }
Write-Host ""
Write-Host "  Service commands:" -ForegroundColor DarkGray
Write-Host "    Start-Service $serviceName"   -ForegroundColor DarkGray
Write-Host "    Stop-Service $serviceName"    -ForegroundColor DarkGray
Write-Host "    Restart-Service $serviceName" -ForegroundColor DarkGray
Write-Host ""

# Show all instances
$allInstances = @(Get-InstalledApaches)
if ($allInstances.Count -gt 1) {
    Write-Host "  All installed instances:" -ForegroundColor DarkCyan
    foreach ($inst in $allInstances) {
        $addr = if ($inst.Port -eq '80') { 'http://localhost' } else { "http://localhost:$($inst.Port)" }
        Write-Host "    $($inst.ServiceName)  $addr  $($inst.InstallDir)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Log "Installation complete" 'OK'
Write-Log "==========================================" 'INFO'

Start-Sleep -Seconds 1
Start-Process $checkUrl
