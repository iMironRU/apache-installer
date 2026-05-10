<#
.SYNOPSIS
    Apache HTTP Server 2.4 — Windows Installer (multilingual: en, ru)
.DESCRIPTION
    Automated installer for Apache HTTP Server on Windows.
    Supports multiple instances on different ports.
    Compatible with ps2exe compilation to standalone .exe

    Language: auto-detected from $PSUICulture, override with -Lang en|ru.

.NOTES
    Copyright (c) 2026 imiron.ru
    Licensed under the Apache License 2.0
    https://github.com/imiron-ru/apache-installer

    Requires: Windows 7+, PowerShell 5.1+, Administrator rights
    Compile:  Invoke-ps2exe .\install-apache.ps1 .\install-apache.exe -requireAdmin -noConsole:$false

.PARAMETER Lang
    UI language: 'en' or 'ru'. If omitted, auto-detected from system locale.
#>

param(
    [ValidateSet('en','ru','')]
    [string]$Lang = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -----------------------------------------------
#  Language selection (must run before anything user-visible)
# -----------------------------------------------
if (-not $Lang) {
    if ($PSUICulture -match '^ru') { $script:Lang = 'ru' } else { $script:Lang = 'en' }
} else {
    $script:Lang = $Lang.ToLower()
}

# -----------------------------------------------
#  String dictionary — all user-visible text lives here.
#  Keys are English; values are localized.
#  Logs always stay English (see Write-Log).
# -----------------------------------------------
$Strings = @{
    en = @{
        # Common
        AdminRequired         = 'Run this script as Administrator.'
        InvalidChoice         = 'Invalid choice.'
        Cancelled             = 'Cancelled.'
        ExitMsg               = 'Exit.'
        AnswerRequired        = 'An answer is required.'
        # Confirmation hints
        HintYes               = 'Y - yes, N - no'
        HintYesDefault        = 'Y - yes [default], N - no'
        HintNoDefault         = 'Y - yes, N - no [default]'
        HintNoDefault0        = 'Y - yes, N - no'
        # Banner
        BannerTitle           = 'Apache HTTP Server Installer'
        BannerSubtitle        = 'localhost | Windows x86/x64'
        LabelLog              = 'Log'
        # Main menu
        MainMenuPrompt        = 'Select action:'
        MainMenuInstall       = 'Install new Apache instance'
        MainMenuRemove        = 'Remove Apache instance'
        MainMenuRemoveDisabled = 'Remove Apache instance  [none installed]'
        MainMenuChangePort    = 'Change port'
        MainMenuChangeName    = 'Change service name'
        MainMenuChangeBitness = 'Change Apache bitness'
        MainMenuExit          = 'Exit'
        InstalledInstances    = 'Installed instances:'
        NoInstancesToRemove   = 'No installed instances to remove.'
        NoInstancesForAction  = 'No installed instances - this action is unavailable.'
        ChoicePromptN         = 'Your choice (1-{0})'
        SelectInstancePrompt  = 'Select Apache instance:'
        PressEnterToContinue  = 'Press Enter to return to the main menu...'
        OperationCancelled    = 'Operation cancelled.'
        # Headers
        HdrSystemDetection    = 'System Detection'
        HdrVCRedist           = 'Visual C++ Redistributable'
        HdrInstallFolder      = 'Installation Folder'
        HdrPort               = 'Port'
        HdrServiceName        = 'Service Name'
        HdrFirewall           = 'Windows Firewall'
        Hdr1C                 = '1C:Enterprise Integration'
        HdrDiskSpace          = 'Disk Space Check'
        HdrPrep               = 'Preparation'
        HdrDownload           = 'Download'
        HdrInstall            = 'Installation'
        HdrService            = 'Windows Service'
        HdrVerification       = 'Verification'
        HdrDone               = 'Done!'
        HdrRemoveInstance     = 'Remove Apache Instance'
        HdrChangePort         = 'Change Apache Port'
        HdrChangeName         = 'Change Service Name'
        HdrChangeBitness      = 'Change Apache Bitness'
        # OS detection
        OsDetected            = 'OS: Windows {0}-bit'
        OsValueShort          = 'Windows {0}-bit'
        # VC++
        VCChecking            = 'Checking Visual C++ Redistributable ({0}-bit)...'
        VCOk                  = 'Visual C++ Redistributable {0} - OK'
        VCOutdated            = 'Outdated VC++ Redistributable: {0} (need {1})'
        VCNotFound            = 'Visual C++ Redistributable ({0}-bit) not found!'
        VCApacheWontStart     = 'Apache will not start without it.'
        VCOptions             = 'Options:'
        VCOpt1                = '[1] Download and install automatically (recommended)'
        VCOpt2                = '[2] Open download page (install manually)'
        VCOpt3                = '[3] Skip (Apache may not start)'
        VCSkipped             = 'VC++ Redistributable skipped.'
        VCInstallManual       = 'Install VC++ Redistributable and press Enter to continue...'
        VCDownloading         = 'Downloading VC++ Redistributable ({0})...'
        VCDownloadFailed      = 'Download failed: {0}'
        VCInstallingSilent    = 'Installing VC++ Redistributable (silent)...'
        VCInstalled           = 'VC++ Redistributable installed.'
        VCInstalledReboot     = 'VC++ installed. Reboot required.'
        VCRebootBefore        = 'Please reboot before starting Apache.'
        VCExitCode            = 'VC++ installer returned code {0}.'
        VCInstallError        = 'Installation error: {0}'
        # 1C
        C1Searching           = 'Searching for 1C:Enterprise platform ({0}-bit)...'
        C1NotFound            = '1C:Enterprise platform ({0}-bit) not found in Program Files\1cv8.'
        C1Found               = 'Found 1C platform: {0}'
        C1Path                = 'Path: {0}'
        C1WsapMissing         = 'wsap24.dll NOT FOUND at: {0}'
        C1WsapNoPub           = '1C web publication will not work without it.'
        C1WsapReinstall       = "Reinstall 1C platform with 'Web server extension modules' option enabled."
        C1WsapFound           = 'wsap24.dll found: {0}'
        C1WsapAddPrompt       = 'Add wsap24.dll to Apache configuration?'
        C1WsapAdded           = 'wsap24.dll will be added to httpd.conf'
        C1WsapNotAdded        = 'wsap24.dll will not be added.'
        C1FoundBoth           = 'Found 1C platforms (both architectures):'
        C1Select              = 'Select 1C platform to use with Apache:'
        BitnessConflictMsg    = 'Found 1C {0}-bit, but wsap24.dll is missing.'
        BitnessConflictHelp   = 'Apache must match 1C bitness for web publication to work.'
        BitnessOptions        = 'Options:'
        BitnessOpt1C          = '[1] Install Apache {0}-bit (matching 1C; reinstall 1C with web extension to enable integration later)'
        BitnessOptOs          = '[2] Install Apache {0}-bit (matching OS; no 1C integration)'
        BitnessForInstall     = 'Apache {0}-bit will be installed.'
        BitnessByOs           = 'No 1C platform found - Apache bitness will match OS ({0}-bit).'
        BitnessAuto           = 'Apache bitness selected automatically: {0}-bit'
        # Folder
        FolderSelectPrompt    = 'Select installation folder:'
        FolderExistsMark      = '[exists]'
        FolderEnterCustom     = 'Enter custom path'
        FolderEnterFullPath   = 'Enter full path (e.g. C:\MyApache)'
        FolderEmptyPath       = 'Path cannot be empty.'
        FolderNoSpaces        = 'Path must not contain spaces.'
        FolderUsedByInstance  = 'This folder is used by instance {0} (port {1}).'
        FolderReinstallAsk    = 'Reinstall this instance?'
        FolderAlreadyExists   = 'Folder {0} already exists.'
        FolderUseExistingAsk  = 'Use this folder? (backup will be offered)'
        FolderResult          = 'Folder: {0}'
        # Port
        PortSelectPrompt      = 'Select port for Apache:'
        PortFreeMark          = '[free]'
        PortBusyMark          = '[BUSY: {0}]'
        PortUsedByMark        = '[used by {0}]'
        PortEnterCustom       = 'Enter custom port'
        PortEnterRange        = 'Enter port (1024-65535)'
        PortInvalid           = 'Port must be a number between 1024-65535.'
        PortUsedByInstanceFmt = 'Port {0} is used by {1} in {2}.'
        PortUseAnywayAsk      = 'Use this port anyway?'
        PortIsBusyFmt         = 'Port {0} is busy: {1}'
        PortResult            = 'Port: {0}'
        # Service name
        SvcDefaultLine        = 'Default service name: {0}'
        SvcChangePrompt       = 'Change default service name?'
        SvcExistsInScm        = "Service '{0}' already exists in SCM."
        SvcFallbackExists     = "Fallback '{0}' also exists. Please choose a custom name."
        SvcUsingFallback      = 'Using fallback name: {0}'
        SvcEnterName          = 'Enter service name'
        SvcEmptyName          = 'Name cannot be empty.'
        SvcNameSpaces         = 'Name must not contain spaces.'
        SvcNameChars          = "Name may contain only letters, digits, '_', '-', '.'"
        SvcNameTaken          = "Service '{0}' already exists. Try another name."
        SvcResult             = 'Service: {0}'
        # Firewall
        FwAskOpen             = 'Open port {0} in Windows Firewall?'
        FwWillAdd             = 'Firewall rule will be added.'
        FwWillSkip            = 'Firewall rule will be skipped.'
        FwAdding              = 'Adding firewall rule ({0}, port {1})...'
        FwAdded               = 'Firewall rule added.'
        FwError               = 'Firewall rule error: {0}'
        FwSkippedByUser       = 'Firewall rule skipped (user choice).'
        # Installation parameters box
        BoxParams             = 'Installation parameters'
        BoxFolder             = 'Folder'
        BoxPort               = 'Port'
        BoxService            = 'Service'
        BoxFirewall           = 'Firewall'
        BoxWsap               = 'wsap24'
        BoxOs                 = 'OS'
        FwOpenPortShort       = 'open port'
        FwSkipShort           = 'skip'
        WsapAddShort          = 'add to config'
        WsapFoundSkipShort    = 'found, skip'
        WsapNotAvailShort     = 'not available'
        AskStartInstall       = 'Start installation?'
        # Disk space
        DiskOk                = 'Disk space OK: {0} MB free (need {1} MB)'
        DiskNotEnough         = 'Not enough disk space for {0}. Free: {1} MB, need: {2} MB.'
        PurposeApache         = 'Apache installation'
        PurposeTemp           = 'temp archive'
        # Backup
        BackupOptions         = 'Backup options:'
        BackupOpt1            = '[1] Config only (conf\)  ~1 MB, fast'
        BackupOpt2            = '[2] Full folder'
        BackupOpt3            = '[3] Both'
        BackupOpt4            = '[4] Skip backup'
        BackupSkipped         = 'Backup skipped.'
        BackupArchivingConf   = 'Archiving config -> {0}'
        BackupConfDone        = 'Config backup: {0} ({1} MB)'
        BackupConfError       = 'Config backup error: {0}'
        BackupNoSpaceConf     = 'Not enough space for config backup.'
        BackupArchivingFull   = 'Archiving full folder -> {0}'
        BackupFullDone        = 'Full backup: {0} ({1} MB)'
        BackupFullError       = 'Full backup error: {0}'
        BackupNoSpaceFull     = 'Not enough space for full backup.'
        BackupNoSpace         = 'Not enough space for backup ({0} MB).'
        BackupContinueWithout = 'Continue without backup?'
        BackupSaved           = 'Backup saved: {0}'
        # Download
        DlGettingUrl          = 'Getting download URL ({0}-bit)...'
        DlFailedUrl           = 'Failed to get URL: {0}'
        DlUnexpected          = 'Unexpected server response: {0}'
        DlDistribution        = 'Distribution: {0}'
        DlDownloading         = 'Downloading...'
        DlBitsFailed          = 'BITS failed, switching to WebRequest'
        DlNotSaved            = 'File not saved: {0}'
        DlDownloaded          = 'Downloaded {0} MB'
        # Installation steps
        InstExtracting        = 'Extracting archive...'
        InstExtractError      = 'Extraction error: {0}'
        InstHttpdNotInZip     = 'httpd.exe not found in archive. File may be corrupted.'
        InstMoveError         = 'Move error: {0}'
        InstExtractedTo       = 'Extracted to {0}'
        InstWritingConf       = 'Writing httpd.conf...'
        InstConfDone          = 'httpd.conf written.'
        InstConfDoneWsap      = 'httpd.conf written (with wsap24.dll integration).'
        InstConfError         = 'httpd.conf write error: {0}'
        InstWritingHtml       = 'Writing index.html...'
        InstHtmlDone          = 'index.html written.'
        InstHtmlError         = 'index.html write error: {0}'
        # Service operations
        SvcStopping           = 'Stopping service {0}...'
        SvcRemoving           = 'Removing service {0}...'
        SvcRemoved            = 'Service {0} removed.'
        SvcRegistering        = 'Registering service {0}...'
        SvcHttpdNotFound      = 'httpd.exe not found: {0}'
        SvcNotInScm           = 'Service {0} not found in SCM after registration.'
        SvcRegistered         = 'Service {0} registered.'
        SvcStarting           = 'Starting service...'
        SvcStartError         = 'Could not start service: {0}'
        SvcDidNotStart        = 'Service {0} did not start.'
        SvcErrorLogLabel      = 'error_log:'
        SvcStarted            = 'Service {0} started.'
        SvcHttpdFailedCode    = 'httpd.exe failed with code {0}.'
        # Verification
        VerGet                = 'GET {0} ...'
        VerOk                 = 'Server responded HTTP 200 - works!'
        VerWrongResponse      = 'Response: {0}. Check: {1}'
        # Summary
        SumAddress            = 'Address'
        SumService            = 'Service'
        SumFolder             = 'Folder'
        SumFirewall           = 'Firewall'
        SumWsap               = 'wsap24'
        SumLog                = 'Log'
        SumBackup             = 'Backup'
        SumFwAdded            = 'rule added'
        SumFwNotConfigured    = 'not configured'
        SumServiceCommands    = 'Service commands:'
        SumAllInstances       = 'All installed instances:'
        # Remove
        RemSelectPrompt       = 'Select instance to remove:'
        RemWillRemove         = 'Will be removed:'
        RemAskConfirm         = 'Remove this instance?'
        RemFolderRemoving     = 'Removing folder {0}...'
        RemFolderRemoved      = 'Folder removed.'
        RemFolderError        = 'Could not remove folder: {0}'
        RemDone               = 'Instance {0} removed.'
        RemPortLabel          = 'port {0}'
        RemFwAsk              = 'Remove the firewall rule for port {0} as well?'
        RemFwKept             = 'Firewall rule kept.'
        RemFwRemoved          = 'Firewall rule removed.'
        # Change Port
        ChPortCurrent         = 'Current port: {0}'
        ChPortSelectNew       = 'Select new port:'
        ChPortSameError       = 'New port is the same as current.'
        ChPortConfirm         = 'Change port from {0} to {1}?'
        ChPortApplying        = 'Changing port from {0} to {1}...'
        ChPortStopping        = 'Stopping service for changes...'
        ChPortUpdConf         = 'Updating httpd.conf...'
        ChPortUpdHtml         = 'Updating index.html...'
        ChPortUpdFw           = 'Updating firewall rule...'
        ChPortAddNewFwAsk     = 'Open new port {0} in Windows Firewall?'
        ChPortRestarting      = 'Starting service...'
        ChPortChanged         = 'Port changed: {0} -> {1}'
        # Change Service Name
        ChSvcCurrent          = 'Current service name: {0}'
        ChSvcEnterNew         = 'Enter new service name'
        ChSvcSameError        = 'New name is the same as current.'
        ChSvcConfirm          = "Change service name from '{0}' to '{1}'?"
        ChSvcApplying         = "Changing service name from '{0}' to '{1}'..."
        ChSvcUninstalling     = 'Uninstalling old service {0}...'
        ChSvcInstallingNew    = 'Installing new service {0}...'
        ChSvcChanged          = "Service name changed: '{0}' -> '{1}'"
        ChSvcOldLingering     = 'Note: the old service entry may remain in SCM until you close any open Services consoles or reboot. The new service is fully operational.'
        # Change Bitness
        ChBitsCurrent         = 'Current Apache bitness: {0}-bit'
        ChBitsTarget          = 'Target bitness: {0}-bit'
        ChBitsConfirm         = 'Change Apache bitness from {0}-bit to {1}-bit?'
        ChBitsApplying        = 'Changing Apache bitness from {0}-bit to {1}-bit...'
        ChBitsKeepUserFiles   = 'Keeping user files: conf/, htdocs/, logs/'
        ChBitsReplacingBin    = 'Replacing Apache binaries...'
        ChBitsCleaningOld     = 'Removing old binaries (keeping conf/, htdocs/, logs/)...'
        ChBitsExtractingNew   = 'Deploying new binaries...'
        ChBitsChanged         = 'Apache bitness changed: {0}-bit -> {1}-bit'
        ChBitsRecheckVC       = 'VC++ Redistributable check for new bitness...'
        # Verification
        VerGet                = 'GET {0} ...'
        VerOk                 = 'Server responded HTTP 200 - works!'
        VerWrongResponse      = 'Response: {0}. Check: {1}'
        OpeningBrowser        = 'Opening {0} in browser...'
        # Cleanup
        CleanupAfterError     = 'Cleaning up after error...'
        # Errors
        ErrAtLine             = 'Error at line {0} : {1}'
        ErrLogPath            = 'Log: {0}'
        # Prep
        PrepRemovingOld       = 'Removing {0}...'
        PrepOldRemoved        = 'Old installation removed.'
        # HTML
        HtmlRunning           = 'Apache is running'
        HtmlServiceLabel      = 'Service'
        HtmlActive            = 'Active'
        HtmlAddress           = 'Address'
        HtmlDirectory         = 'Directory'
        HtmlConfig            = 'Config'
        HtmlApacheLogs        = 'Apache logs'
        HtmlStatus            = 'Status'
        HtmlInstallLog        = 'Install log'
    }

    ru = @{
        # Common
        AdminRequired         = 'Запустите скрипт от имени Администратора.'
        InvalidChoice         = 'Неверный выбор.'
        Cancelled             = 'Отменено.'
        ExitMsg               = 'Выход.'
        AnswerRequired        = 'Требуется ответ.'
        # Confirmation hints
        HintYes               = 'Y/Д - да, N/Н - нет'
        HintYesDefault        = 'Y/Д - да [по умолчанию], N/Н - нет'
        HintNoDefault         = 'Y/Д - да, N/Н - нет [по умолчанию]'
        HintNoDefault0        = 'Y/Д - да, N/Н - нет'
        # Banner
        BannerTitle           = 'Установщик Apache HTTP Server'
        BannerSubtitle        = 'localhost | Windows x86/x64'
        LabelLog              = 'Журнал'
        # Main menu
        MainMenuPrompt        = 'Выберите действие:'
        MainMenuInstall       = 'Установить новый экземпляр Apache'
        MainMenuRemove        = 'Удалить экземпляр Apache'
        MainMenuRemoveDisabled = 'Удалить экземпляр Apache  [нет установленных]'
        MainMenuChangePort    = 'Сменить порт'
        MainMenuChangeName    = 'Сменить имя службы'
        MainMenuChangeBitness = 'Сменить разрядность Apache'
        MainMenuExit          = 'Выход'
        InstalledInstances    = 'Установленные экземпляры:'
        NoInstancesToRemove   = 'Нет установленных экземпляров для удаления.'
        NoInstancesForAction  = 'Нет установленных экземпляров - действие недоступно.'
        ChoicePromptN         = 'Ваш выбор (1-{0})'
        SelectInstancePrompt  = 'Выберите экземпляр Apache:'
        PressEnterToContinue  = 'Нажмите Enter для возврата в главное меню...'
        OperationCancelled    = 'Операция отменена.'
        # Headers
        HdrSystemDetection    = 'Определение системы'
        HdrVCRedist           = 'Visual C++ Redistributable'
        HdrInstallFolder      = 'Папка установки'
        HdrPort               = 'Порт'
        HdrServiceName        = 'Имя службы'
        HdrFirewall           = 'Брандмауэр Windows'
        Hdr1C                 = 'Интеграция с 1С:Предприятие'
        HdrDiskSpace          = 'Проверка дискового пространства'
        HdrPrep               = 'Подготовка'
        HdrDownload           = 'Загрузка'
        HdrInstall            = 'Установка'
        HdrService            = 'Служба Windows'
        HdrVerification       = 'Проверка'
        HdrDone               = 'Готово!'
        HdrRemoveInstance     = 'Удаление экземпляра Apache'
        HdrChangePort         = 'Смена порта Apache'
        HdrChangeName         = 'Смена имени службы'
        HdrChangeBitness      = 'Смена разрядности Apache'
        # OS detection
        OsDetected            = 'ОС: Windows {0}-разрядная'
        OsValueShort          = 'Windows {0}-разрядная'
        # VC++
        VCChecking            = 'Проверка Visual C++ Redistributable ({0}-разрядный)...'
        VCOk                  = 'Visual C++ Redistributable {0} - OK'
        VCOutdated            = 'Устаревший VC++ Redistributable: {0} (нужно {1})'
        VCNotFound            = 'Visual C++ Redistributable ({0}-разрядный) не найден!'
        VCApacheWontStart     = 'Apache не запустится без него.'
        VCOptions             = 'Варианты:'
        VCOpt1                = '[1] Загрузить и установить автоматически (рекомендуется)'
        VCOpt2                = '[2] Открыть страницу загрузки (установка вручную)'
        VCOpt3                = '[3] Пропустить (Apache может не запуститься)'
        VCSkipped             = 'VC++ Redistributable пропущен.'
        VCInstallManual       = 'Установите VC++ Redistributable и нажмите Enter для продолжения...'
        VCDownloading         = 'Загрузка VC++ Redistributable ({0})...'
        VCDownloadFailed      = 'Ошибка загрузки: {0}'
        VCInstallingSilent    = 'Установка VC++ Redistributable (тихий режим)...'
        VCInstalled           = 'VC++ Redistributable установлен.'
        VCInstalledReboot     = 'VC++ установлен. Требуется перезагрузка.'
        VCRebootBefore        = 'Перезагрузите компьютер перед запуском Apache.'
        VCExitCode            = 'Установщик VC++ вернул код {0}.'
        VCInstallError        = 'Ошибка установки: {0}'
        # 1C
        C1Searching           = 'Поиск платформы 1С:Предприятие ({0}-разрядная)...'
        C1NotFound            = 'Платформа 1С:Предприятие ({0}-разрядная) не найдена в Program Files\1cv8.'
        C1Found               = 'Найдена платформа 1С: {0}'
        C1Path                = 'Путь: {0}'
        C1WsapMissing         = 'wsap24.dll НЕ НАЙДЕН по пути: {0}'
        C1WsapNoPub           = 'Веб-публикация 1С не будет работать без него.'
        C1WsapReinstall       = "Переустановите платформу 1С с включённым компонентом 'Модули расширения веб-сервера'."
        C1WsapFound           = 'wsap24.dll найден: {0}'
        C1WsapAddPrompt       = 'Добавить wsap24.dll в конфигурацию Apache?'
        C1WsapAdded           = 'wsap24.dll будет добавлен в httpd.conf'
        C1WsapNotAdded        = 'wsap24.dll не будет добавлен.'
        C1FoundBoth           = 'Найдены платформы 1С (обеих разрядностей):'
        C1Select              = 'Выберите платформу 1С для работы с Apache:'
        BitnessConflictMsg    = 'Найдена 1С {0}-разрядная, но wsap24.dll отсутствует.'
        BitnessConflictHelp   = 'Для работы веб-публикации Apache должен совпадать по разрядности с 1С.'
        BitnessOptions        = 'Варианты:'
        BitnessOpt1C          = '[1] Установить Apache {0}-разрядный (под 1С; переустановите 1С с компонентом веб-расширения для интеграции)'
        BitnessOptOs          = '[2] Установить Apache {0}-разрядный (под ОС; без интеграции с 1С)'
        BitnessForInstall     = 'Будет установлен Apache {0}-разрядный.'
        BitnessByOs           = 'Платформа 1С не найдена - разрядность Apache совпадёт с ОС ({0}-разрядная).'
        BitnessAuto           = 'Разрядность Apache выбрана автоматически: {0}-разрядная'
        # Folder
        FolderSelectPrompt    = 'Выберите папку установки:'
        FolderExistsMark      = '[существует]'
        FolderEnterCustom     = 'Ввести свой путь'
        FolderEnterFullPath   = 'Введите полный путь (например, C:\MyApache)'
        FolderEmptyPath       = 'Путь не может быть пустым.'
        FolderNoSpaces        = 'Путь не должен содержать пробелов.'
        FolderUsedByInstance  = 'Эта папка используется экземпляром {0} (порт {1}).'
        FolderReinstallAsk    = 'Переустановить этот экземпляр?'
        FolderAlreadyExists   = 'Папка {0} уже существует.'
        FolderUseExistingAsk  = 'Использовать эту папку? (будет предложено резервное копирование)'
        FolderResult          = 'Папка: {0}'
        # Port
        PortSelectPrompt      = 'Выберите порт для Apache:'
        PortFreeMark          = '[свободен]'
        PortBusyMark          = '[ЗАНЯТ: {0}]'
        PortUsedByMark        = '[используется {0}]'
        PortEnterCustom       = 'Ввести свой порт'
        PortEnterRange        = 'Введите порт (1024-65535)'
        PortInvalid           = 'Порт должен быть числом от 1024 до 65535.'
        PortUsedByInstanceFmt = 'Порт {0} используется службой {1} в {2}.'
        PortUseAnywayAsk      = 'Использовать этот порт несмотря на это?'
        PortIsBusyFmt         = 'Порт {0} занят: {1}'
        PortResult            = 'Порт: {0}'
        # Service name
        SvcDefaultLine        = 'Имя службы по умолчанию: {0}'
        SvcChangePrompt       = 'Изменить имя службы по умолчанию?'
        SvcExistsInScm        = "Служба '{0}' уже существует в SCM."
        SvcFallbackExists     = "Резервное имя '{0}' тоже занято. Выберите своё имя."
        SvcUsingFallback      = 'Используется резервное имя: {0}'
        SvcEnterName          = 'Введите имя службы'
        SvcEmptyName          = 'Имя не может быть пустым.'
        SvcNameSpaces         = 'Имя не должно содержать пробелов.'
        SvcNameChars          = "Имя может содержать только латинские буквы, цифры и '_', '-', '.'"
        SvcNameTaken          = "Служба '{0}' уже существует. Попробуйте другое имя."
        SvcResult             = 'Служба: {0}'
        # Firewall
        FwAskOpen             = 'Открыть порт {0} в брандмауэре Windows?'
        FwWillAdd             = 'Правило брандмауэра будет добавлено.'
        FwWillSkip            = 'Правило брандмауэра будет пропущено.'
        FwAdding              = 'Добавление правила брандмауэра ({0}, порт {1})...'
        FwAdded               = 'Правило брандмауэра добавлено.'
        FwError               = 'Ошибка правила брандмауэра: {0}'
        FwSkippedByUser       = 'Правило брандмауэра пропущено (выбор пользователя).'
        # Installation parameters box
        BoxParams             = 'Параметры установки'
        BoxFolder             = 'Папка'
        BoxPort               = 'Порт'
        BoxService            = 'Служба'
        BoxFirewall           = 'Брандмауэр'
        BoxWsap               = 'wsap24'
        BoxOs                 = 'ОС'
        FwOpenPortShort       = 'открыть порт'
        FwSkipShort           = 'пропустить'
        WsapAddShort          = 'добавить в конфиг'
        WsapFoundSkipShort    = 'найден, пропустить'
        WsapNotAvailShort     = 'недоступен'
        AskStartInstall       = 'Начать установку?'
        # Disk space
        DiskOk                = 'Места достаточно: {0} МБ свободно (нужно {1} МБ)'
        DiskNotEnough         = 'Недостаточно места для {0}. Свободно: {1} МБ, нужно: {2} МБ.'
        PurposeApache         = 'установки Apache'
        PurposeTemp           = 'временного архива'
        # Backup
        BackupOptions         = 'Варианты резервного копирования:'
        BackupOpt1            = '[1] Только конфиг (conf\)  ~1 МБ, быстро'
        BackupOpt2            = '[2] Вся папка'
        BackupOpt3            = '[3] Оба варианта'
        BackupOpt4            = '[4] Пропустить резервное копирование'
        BackupSkipped         = 'Резервное копирование пропущено.'
        BackupArchivingConf   = 'Архивирование конфига -> {0}'
        BackupConfDone        = 'Резервная копия конфига: {0} ({1} МБ)'
        BackupConfError       = 'Ошибка резервного копирования конфига: {0}'
        BackupNoSpaceConf     = 'Недостаточно места для резервной копии конфига.'
        BackupArchivingFull   = 'Архивирование всей папки -> {0}'
        BackupFullDone        = 'Полная резервная копия: {0} ({1} МБ)'
        BackupFullError       = 'Ошибка полного резервного копирования: {0}'
        BackupNoSpaceFull     = 'Недостаточно места для полной резервной копии.'
        BackupNoSpace         = 'Недостаточно места для резервной копии ({0} МБ).'
        BackupContinueWithout = 'Продолжить без резервного копирования?'
        BackupSaved           = 'Резервная копия сохранена: {0}'
        # Download
        DlGettingUrl          = 'Получение URL загрузки ({0}-разрядный)...'
        DlFailedUrl           = 'Не удалось получить URL: {0}'
        DlUnexpected          = 'Неожиданный ответ сервера: {0}'
        DlDistribution        = 'Дистрибутив: {0}'
        DlDownloading         = 'Загрузка...'
        DlBitsFailed          = 'BITS не сработал, переключение на WebRequest'
        DlNotSaved            = 'Файл не сохранён: {0}'
        DlDownloaded          = 'Загружено {0} МБ'
        # Installation steps
        InstExtracting        = 'Распаковка архива...'
        InstExtractError      = 'Ошибка распаковки: {0}'
        InstHttpdNotInZip     = 'httpd.exe не найден в архиве. Файл может быть повреждён.'
        InstMoveError         = 'Ошибка перемещения: {0}'
        InstExtractedTo       = 'Распаковано в {0}'
        InstWritingConf       = 'Запись httpd.conf...'
        InstConfDone          = 'httpd.conf записан.'
        InstConfDoneWsap      = 'httpd.conf записан (с интеграцией wsap24.dll).'
        InstConfError         = 'Ошибка записи httpd.conf: {0}'
        InstWritingHtml       = 'Запись index.html...'
        InstHtmlDone          = 'index.html записан.'
        InstHtmlError         = 'Ошибка записи index.html: {0}'
        # Service operations
        SvcStopping           = 'Остановка службы {0}...'
        SvcRemoving           = 'Удаление службы {0}...'
        SvcRemoved            = 'Служба {0} удалена.'
        SvcRegistering        = 'Регистрация службы {0}...'
        SvcHttpdNotFound      = 'httpd.exe не найден: {0}'
        SvcNotInScm           = 'Служба {0} не найдена в SCM после регистрации.'
        SvcRegistered         = 'Служба {0} зарегистрирована.'
        SvcStarting           = 'Запуск службы...'
        SvcStartError         = 'Не удалось запустить службу: {0}'
        SvcDidNotStart        = 'Служба {0} не запустилась.'
        SvcErrorLogLabel      = 'error_log:'
        SvcStarted            = 'Служба {0} запущена.'
        SvcHttpdFailedCode    = 'httpd.exe завершился с кодом {0}.'
        # Verification
        VerGet                = 'GET {0} ...'
        VerOk                 = 'Сервер ответил HTTP 200 - работает!'
        VerWrongResponse      = 'Ответ: {0}. Проверьте: {1}'
        # Summary
        SumAddress            = 'Адрес'
        SumService            = 'Служба'
        SumFolder             = 'Папка'
        SumFirewall           = 'Брандмауэр'
        SumWsap               = 'wsap24'
        SumLog                = 'Журнал'
        SumBackup             = 'Резервная копия'
        SumFwAdded            = 'правило добавлено'
        SumFwNotConfigured    = 'не настроено'
        SumServiceCommands    = 'Команды управления службой:'
        SumAllInstances       = 'Все установленные экземпляры:'
        # Remove
        RemSelectPrompt       = 'Выберите экземпляр для удаления:'
        RemWillRemove         = 'Будет удалено:'
        RemAskConfirm         = 'Удалить этот экземпляр?'
        RemFolderRemoving     = 'Удаление папки {0}...'
        RemFolderRemoved      = 'Папка удалена.'
        RemFolderError        = 'Не удалось удалить папку: {0}'
        RemDone               = 'Экземпляр {0} удалён.'
        RemPortLabel          = 'порт {0}'
        RemFwAsk              = 'Удалить также правило брандмауэра для порта {0}?'
        RemFwKept             = 'Правило брандмауэра сохранено.'
        RemFwRemoved          = 'Правило брандмауэра удалено.'
        # Change Port
        ChPortCurrent         = 'Текущий порт: {0}'
        ChPortSelectNew       = 'Выберите новый порт:'
        ChPortSameError       = 'Новый порт совпадает с текущим.'
        ChPortConfirm         = 'Изменить порт с {0} на {1}?'
        ChPortApplying        = 'Смена порта с {0} на {1}...'
        ChPortStopping        = 'Остановка службы для применения изменений...'
        ChPortUpdConf         = 'Обновление httpd.conf...'
        ChPortUpdHtml         = 'Обновление index.html...'
        ChPortUpdFw           = 'Обновление правила брандмауэра...'
        ChPortAddNewFwAsk     = 'Открыть новый порт {0} в брандмауэре Windows?'
        ChPortRestarting      = 'Запуск службы...'
        ChPortChanged         = 'Порт изменён: {0} -> {1}'
        # Change Service Name
        ChSvcCurrent          = 'Текущее имя службы: {0}'
        ChSvcEnterNew         = 'Введите новое имя службы'
        ChSvcSameError        = 'Новое имя совпадает с текущим.'
        ChSvcConfirm          = "Изменить имя службы с '{0}' на '{1}'?"
        ChSvcApplying         = "Смена имени службы с '{0}' на '{1}'..."
        ChSvcUninstalling     = 'Удаление старой службы {0}...'
        ChSvcInstallingNew    = 'Установка новой службы {0}...'
        ChSvcChanged          = "Имя службы изменено: '{0}' -> '{1}'"
        ChSvcOldLingering     = 'Примечание: запись старой службы может остаться в SCM до закрытия открытых консолей служб или перезагрузки. Новая служба работает корректно.'
        # Change Bitness
        ChBitsCurrent         = 'Текущая разрядность Apache: {0}-разрядная'
        ChBitsTarget          = 'Целевая разрядность: {0}-разрядная'
        ChBitsConfirm         = 'Сменить разрядность Apache с {0}-разрядной на {1}-разрядную?'
        ChBitsApplying        = 'Смена разрядности Apache с {0}-разрядной на {1}-разрядную...'
        ChBitsKeepUserFiles   = 'Сохраняем пользовательские файлы: conf/, htdocs/, logs/'
        ChBitsReplacingBin    = 'Замена бинарных файлов Apache...'
        ChBitsCleaningOld     = 'Удаление старых бинарных файлов (с сохранением conf/, htdocs/, logs/)...'
        ChBitsExtractingNew   = 'Развёртывание новых бинарных файлов...'
        ChBitsChanged         = 'Разрядность Apache изменена: {0}-разрядная -> {1}-разрядная'
        ChBitsRecheckVC       = 'Проверка VC++ Redistributable для новой разрядности...'
        # Verification
        VerGet                = 'GET {0} ...'
        VerOk                 = 'Сервер ответил HTTP 200 - работает!'
        VerWrongResponse      = 'Ответ: {0}. Проверьте: {1}'
        OpeningBrowser        = 'Открытие {0} в браузере...'
        # Cleanup
        CleanupAfterError     = 'Очистка после ошибки...'
        # Errors
        ErrAtLine             = 'Ошибка в строке {0}: {1}'
        ErrLogPath            = 'Журнал: {0}'
        # Prep
        PrepRemovingOld       = 'Удаление {0}...'
        PrepOldRemoved        = 'Старая установка удалена.'
        # HTML
        HtmlRunning           = 'Apache запущен'
        HtmlServiceLabel      = 'Служба'
        HtmlActive            = 'Активен'
        HtmlAddress           = 'Адрес'
        HtmlDirectory         = 'Каталог'
        HtmlConfig            = 'Конфиг'
        HtmlApacheLogs        = 'Логи Apache'
        HtmlStatus            = 'Статус'
        HtmlInstallLog        = 'Журнал установки'
    }
}

# Build effective string table: en as base, current language overlays.
# Guarantees $L.AnyKey is non-null even if a translation is missing.
$L = @{}
foreach ($k in $Strings.en.Keys) { $L[$k] = $Strings.en[$k] }
if ($script:Lang -ne 'en' -and $Strings.ContainsKey($script:Lang)) {
    foreach ($k in $Strings[$script:Lang].Keys) { $L[$k] = $Strings[$script:Lang][$k] }
}

# -----------------------------------------------
#  Admin check (uses $L)
# -----------------------------------------------
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ("  ! " + $L.AdminRequired) -ForegroundColor Red
    exit 1
}

# -----------------------------------------------
#  Working directory — ps1 folder OR exe folder
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
$DEFAULT_SVCNAME = 'Apache2.4'

$LOG_FILE = Join-Path $WORK_DIR ("install-apache-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")

# -----------------------------------------------
#  Logging — log file is always English for support purposes
# -----------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $LOG_FILE -Value "[$ts] [$Level] $Message" -Encoding UTF8
}

# Sanity-check translations at startup (non-fatal)
if ($script:Lang -ne 'en') {
    $missingKeys = @($Strings.en.Keys | Where-Object { -not $Strings[$script:Lang].ContainsKey($_) })
    if ($missingKeys.Count -gt 0) {
        Write-Log ("Missing $script:Lang translations (using en fallback): " + ($missingKeys -join ', ')) 'WARN'
    }
}

trap {
    $errMsg  = $_.Exception.Message
    $errLine = $_.InvocationInfo.ScriptLineNumber
    Write-Log "EXCEPTION line $errLine : $errMsg" 'ERROR'
    Write-Log "Stack: $($_.ScriptStackTrace)" 'ERROR'
    $msgErr = if ($script:L -and $script:L.ContainsKey('ErrAtLine')) {
        $script:L.ErrAtLine -f $errLine, $errMsg
    } else {
        "Error at line $errLine : $errMsg"
    }
    $msgLog = if ($script:L -and $script:L.ContainsKey('ErrLogPath')) {
        $script:L.ErrLogPath -f $LOG_FILE
    } else {
        "Log: $LOG_FILE"
    }
    Write-Fail $msgErr
    Write-Fail $msgLog
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

function Confirm-Action {
    # $Default: $true = default Yes, $false = default No, $null = no default (critical)
    param([string]$Prompt, $Default = $null)

    $hint = if ($null -eq $Default) { $L.HintNoDefault0 }
            elseif ($Default)        { $L.HintYesDefault }
            else                     { $L.HintNoDefault }

    while ($true) {
        $a = (Read-Host "  $Prompt ($hint)").Trim().ToUpper()
        Write-Log "Prompt: $Prompt | Answer: '$a' | Default: $Default" 'INPUT'

        if ([string]::IsNullOrEmpty($a)) {
            if ($null -ne $Default) { return [bool]$Default }
            Write-Warn $L.AnswerRequired
            continue
        }
        # Accept yes-answers in both languages regardless of UI language —
        # users on RU servers often have EN keyboard layout active.
        if ($a -in @('Y','YES','D','DA','Д','ДА'))  { return $true }
        if ($a -in @('N','NO','Н','НЕТ'))           { return $false }

        Write-Warn $L.InvalidChoice
    }
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
# -----------------------------------------------
function Get-InstalledApaches {
    $result = [System.Collections.Generic.List[object]]::new()
    $seen   = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

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

    $apacheSvcs = @(Get-WmiObject Win32_Service -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'Apache*' -or $_.DisplayName -like 'Apache*' })

    foreach ($svc in $apacheSvcs) {
        if ($seen.Contains($svc.Name)) { continue }
        $null = $seen.Add($svc.Name)

        $binPath   = $svc.PathName -replace '"','' -replace '\s+-k.*$',''
        $installDir = if ($binPath) { Split-Path (Split-Path $binPath -Parent) -Parent } else { "unknown" }

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
    Write-Step ($L.VCChecking -f $Bits)
    Write-Log "VC++ Redist check: $Bits-bit, min $VCREDIST_MIN" 'INFO'

    $installed = Get-VCRedistVersion -Bits $Bits
    Write-Log "VC++ Redist found: $installed" 'INFO'

    if ($installed -and $installed -ge $VCREDIST_MIN) {
        Write-OK ($L.VCOk -f $installed)
        return
    }

    if ($installed) {
        Write-Warn ($L.VCOutdated -f $installed, $VCREDIST_MIN)
    } else {
        Write-Warn ($L.VCNotFound -f $Bits)
        Write-Warn $L.VCApacheWontStart
    }

    Write-Host ""
    Write-Host ("  " + $L.VCOptions) -ForegroundColor Cyan
    Write-Host ("    " + $L.VCOpt1)
    Write-Host ("    " + $L.VCOpt2)
    Write-Host ("    " + $L.VCOpt3)
    Write-Host ""

    $vc = Read-Choice -Prompt ($L.ChoicePromptN -f 3) -Default "1"
    Write-Log "VC++ choice: $vc" 'INPUT'

    if ($vc -eq '3') {
        Write-Warn $L.VCSkipped
        return
    }

    $vcUrl  = if ($Bits -eq 64) { $VCREDIST_URL_64 } else { $VCREDIST_URL_32 }
    $vcArch = if ($Bits -eq 64) { 'x64' } else { 'x86' }

    if ($vc -eq '2') {
        Start-Process "https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist"
        Write-Host ("  " + $L.VCInstallManual) -ForegroundColor Yellow
        $null = Read-Host
        return
    }

    $vcTemp = Join-Path $env:TEMP "vc_redist_$vcArch.exe"
    Write-Step ($L.VCDownloading -f $vcArch)
    Write-Log "Downloading: $vcUrl" 'INFO'
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $vcUrl -OutFile $vcTemp -UseBasicParsing
    } catch {
        Write-Warn ($L.VCDownloadFailed -f $_.Exception.Message)
        return
    }

    Write-Step $L.VCInstallingSilent
    try {
        $p = Start-Process -FilePath $vcTemp -ArgumentList '/install','/quiet','/norestart' -Wait -PassThru
        Write-Log "VC++ ExitCode: $($p.ExitCode)" 'INFO'
        if ($p.ExitCode -eq 0)         { Write-OK $L.VCInstalled }
        elseif ($p.ExitCode -eq 3010)  { Write-OK $L.VCInstalledReboot; Write-Warn $L.VCRebootBefore }
        else                           { Write-Warn ($L.VCExitCode -f $p.ExitCode) }
    } catch {
        Write-Warn ($L.VCInstallError -f $_.Exception.Message)
    } finally {
        Remove-Item $vcTemp -Force -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------
#  1C:Enterprise platform / wsap24.dll detection
# -----------------------------------------------
function Find-1CPlatform([int]$Bits) {
    $searchPaths = @()
    if ($Bits -eq 64) {
        if ($env:ProgramFiles) {
            $searchPaths += (Join-Path $env:ProgramFiles '1cv8')
        }
    } else {
        if (${env:ProgramFiles(x86)}) {
            $searchPaths += (Join-Path ${env:ProgramFiles(x86)} '1cv8')
        } elseif ($env:ProgramFiles) {
            $searchPaths += (Join-Path $env:ProgramFiles '1cv8')
        }
    }

    $candidates = @()
    foreach ($base in $searchPaths) {
        if (-not (Test-Path $base)) { continue }
        Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
            ForEach-Object {
                $dll = Join-Path $_.FullName 'bin\wsap24.dll'
                $candidates += [PSCustomObject]@{
                    Version = [Version]$_.Name
                    Path    = $_.FullName
                    DllPath = $dll
                    Exists  = Test-Path $dll
                }
            }
    }

    if ($candidates.Count -eq 0) { return $null }
    return ($candidates | Sort-Object Version -Descending | Select-Object -First 1)
}

function Test-Wsap24([int]$Bits) {
    Write-Step ($L.C1Searching -f $Bits)
    $platform = Find-1CPlatform -Bits $Bits

    if (-not $platform) {
        Write-Warn ($L.C1NotFound -f $Bits)
        Write-Log "1C platform: not found ($Bits-bit)" 'WARN'
        return $null
    }

    Write-OK ($L.C1Found -f $platform.Version)
    Write-Host ("    " + ($L.C1Path -f $platform.Path)) -ForegroundColor DarkGray
    Write-Log "1C platform: $($platform.Version) at $($platform.Path)" 'INFO'

    if (-not $platform.Exists) {
        Write-Warn ($L.C1WsapMissing -f $platform.DllPath)
        Write-Warn $L.C1WsapNoPub
        Write-Warn $L.C1WsapReinstall
        Write-Log "wsap24.dll: missing at $($platform.DllPath)" 'WARN'
        return $null
    }

    Write-OK ($L.C1WsapFound -f $platform.DllPath)
    Write-Log "wsap24.dll: found at $($platform.DllPath)" 'OK'
    return $platform.DllPath
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
        throw ($L.DiskNotEnough -f $Purpose, $free, $RequiredMB)
    }
    Write-OK ($L.DiskOk -f $free, $RequiredMB)
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
        $tail    = if ($exePath) { " - $exePath" } else { '' }
        return "$($proc.ProcessName) (PID: $pid_)$tail"
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
    Write-Step ($L.SvcStopping -f $Name)
    try { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2 } catch {}
}
function Remove-NamedService([string]$Name) {
    if (-not (Test-ServiceExists $Name)) { return }
    Stop-NamedService -Name $Name
    Write-Step ($L.SvcRemoving -f $Name)
    sc.exe delete $Name 2>&1 | Out-Null
    Start-Sleep -Seconds 1
    Write-OK ($L.SvcRemoved -f $Name)
}

# -----------------------------------------------
#  Firewall
# -----------------------------------------------
function Add-ApacheFirewallRule([string]$RuleName, [string]$HttpdExe, [string]$Port) {
    Write-Step ($L.FwAdding -f $RuleName, $Port)
    Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
    try {
        New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Program $HttpdExe `
            -Action Allow -Protocol TCP -LocalPort $Port -Profile Any | Out-Null
        Write-OK $L.FwAdded
        Write-Log "Firewall: $RuleName added" 'OK'
    } catch {
        Write-Warn ($L.FwError -f $_.Exception.Message)
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
    Write-Warn $L.CleanupAfterError
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
    Write-Host ("  " + $L.BackupOptions) -ForegroundColor Cyan
    Write-Host ("    " + $L.BackupOpt1)
    Write-Host ("    " + $L.BackupOpt2)
    Write-Host ("    " + $L.BackupOpt3)
    Write-Host ("    " + $L.BackupOpt4)
    Write-Host ""

    $bc = Read-Choice -Prompt ($L.ChoicePromptN -f 4) -Default "1"
    Write-Log "Backup choice: $bc" 'INPUT'
    if ($bc -eq '4') { Write-Warn $L.BackupSkipped; return $null }

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
                    Write-Step ($L.BackupArchivingConf -f $dst)
                    Compress-Archive -Path "$src\*" -DestinationPath $dst -Force
                    $zipMB = [math]::Round((Get-Item $dst).Length / 1MB, 2)
                    Write-OK ($L.BackupConfDone -f $dst, $zipMB)
                    Write-Log "Backup conf: $zipMB MB" 'OK'
                    $result = $dst
                } catch { Write-Warn ($L.BackupConfError -f $_.Exception.Message) }
            } else { Write-Warn $L.BackupNoSpaceConf }
        }
    }

    if ($bc -eq '2' -or $bc -eq '3') {
        $dst = Join-Path $WORK_DIR "backup-$ts-full.zip"
        $szMB = [math]::Round((Get-ChildItem $InstallDir -Recurse -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum / 1MB + 5)
        if ((Get-FreeDiskSpaceMB $WORK_DIR) -ge ($szMB + 10)) {
            try {
                Write-Step ($L.BackupArchivingFull -f $dst)
                Compress-Archive -Path "$InstallDir\*" -DestinationPath $dst -Force
                $zipMB = [math]::Round((Get-Item $dst).Length / 1MB, 1)
                Write-OK ($L.BackupFullDone -f $dst, $zipMB)
                Write-Log "Backup full: $zipMB MB" 'OK'
                if (-not $result) { $result = $dst }
            } catch { Write-Warn ($L.BackupFullError -f $_.Exception.Message) }
        } else { Write-Warn $L.BackupNoSpaceFull }
    }

    return $result
}

# -----------------------------------------------
#  Naming helpers
# -----------------------------------------------
function Get-FallbackServiceName([string]$Port) { return "Apache_$Port" }
function Get-FwRuleName([string]$Port)           { return "Apache HTTP (port $Port)" }

# -----------------------------------------------
#  Service name selection
# -----------------------------------------------
function Select-ServiceName([string]$Port) {
    Write-Host ""
    Write-Host ("  " + ($L.SvcDefaultLine -f $DEFAULT_SVCNAME)) -ForegroundColor Cyan
    Write-Host ""

    $changeName = Confirm-Action $L.SvcChangePrompt $false

    if (-not $changeName) {
        if (Test-ServiceExists $DEFAULT_SVCNAME) {
            $alt = Get-FallbackServiceName -Port $Port
            Write-Warn ($L.SvcExistsInScm -f $DEFAULT_SVCNAME)
            if (Test-ServiceExists $alt) {
                Write-Warn ($L.SvcFallbackExists -f $alt)
            } else {
                Write-Step ($L.SvcUsingFallback -f $alt)
                Write-Log "Service name: '$DEFAULT_SVCNAME' taken, using '$alt'" 'WARN'
                return $alt
            }
        } else {
            Write-Log "Service name: '$DEFAULT_SVCNAME' (default)" 'INFO'
            return $DEFAULT_SVCNAME
        }
    }

    while ($true) {
        $custom = (Read-Host ("  " + $L.SvcEnterName)).Trim()
        if ([string]::IsNullOrEmpty($custom)) {
            Write-Warn $L.SvcEmptyName; continue
        }
        if ($custom -match '\s') {
            Write-Warn $L.SvcNameSpaces; continue
        }
        if ($custom -notmatch '^[A-Za-z0-9_.\-]+$') {
            Write-Warn $L.SvcNameChars; continue
        }
        if (Test-ServiceExists $custom) {
            Write-Warn ($L.SvcNameTaken -f $custom)
            continue
        }
        Write-Log "Service name: '$custom' (custom)" 'INFO'
        return $custom
    }
}

# -----------------------------------------------
#  Install dir menu
# -----------------------------------------------
function Select-InstallDir {
    $options = @('C:\Apache24', 'D:\Apache24', 'C:\Apache')
    while ($true) {
        Write-Host ""
        Write-Host ("  " + $L.FolderSelectPrompt) -ForegroundColor Cyan
        Write-Host ""
        for ($i = 0; $i -lt $options.Count; $i++) {
            $mark = if (Test-Path $options[$i]) { " " + $L.FolderExistsMark } else { "" }
            Write-Host "    [$($i+1)] $($options[$i])$mark"
        }
        Write-Host ("    [$($options.Count+1)] " + $L.FolderEnterCustom)
        Write-Host ""

        $choice = Read-Choice -Prompt ($L.ChoicePromptN -f ($options.Count + 1)) -Default "1"
        Write-Log "Folder choice: $choice" 'INPUT'

        $selected = $null
        if ($choice -match '^\d+$') {
            $idx = [int]$choice
            if ($idx -ge 1 -and $idx -le $options.Count) { $selected = $options[$idx - 1] }
            elseif ($idx -eq $options.Count + 1) {
                $custom = (Read-Host ("  " + $L.FolderEnterFullPath)).Trim()
                if ([string]::IsNullOrEmpty($custom)) { Write-Warn $L.FolderEmptyPath; continue }
                if ($custom -match ' ') { Write-Warn $L.FolderNoSpaces; continue }
                $selected = $custom
            }
        }
        if (-not $selected) { Write-Warn $L.InvalidChoice; continue }

        $existing = Get-RegInstances | Where-Object { $_.InstallDir -eq $selected }
        if ($existing) {
            Write-Warn ($L.FolderUsedByInstance -f $existing.ServiceName, $existing.Port)
            if (Confirm-Action $L.FolderReinstallAsk) { return $selected }
            continue
        }

        if (Test-Path $selected) {
            Write-Warn ($L.FolderAlreadyExists -f $selected)
            if (Confirm-Action $L.FolderUseExistingAsk) { return $selected }
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
        Write-Host ("  " + $L.PortSelectPrompt) -ForegroundColor Cyan
        Write-Host ""
        for ($i = 0; $i -lt $ports.Count; $i++) {
            $p = $ports[$i]
            if ($usedPorts -contains $p) {
                $inst = Get-RegInstances | Where-Object { $_.Port -eq $p } | Select-Object -First 1
                $mark = $L.PortUsedByMark -f $inst.ServiceName
                Write-Host "    [$($i+1)] $p $mark" -ForegroundColor DarkYellow
            } elseif (Test-PortBusy $p) {
                $mark = $L.PortBusyMark -f (Get-PortOwner $p)
                Write-Host "    [$($i+1)] $p $mark" -ForegroundColor Yellow
            } else {
                Write-Host "    [$($i+1)] $p $($L.PortFreeMark)"
            }
        }
        Write-Host ("    [$($ports.Count+1)] " + $L.PortEnterCustom)
        Write-Host ""

        $choice = Read-Choice -Prompt ($L.ChoicePromptN -f ($ports.Count + 1)) -Default "1"
        Write-Log "Port choice: $choice" 'INPUT'

        $selected = $null
        if ($choice -match '^\d+$') {
            $idx = [int]$choice
            if ($idx -ge 1 -and $idx -le $ports.Count) { $selected = $ports[$idx - 1] }
            elseif ($idx -eq $ports.Count + 1) {
                $custom = (Read-Host ("  " + $L.PortEnterRange)).Trim()
                if ($custom -notmatch '^\d+$' -or [int]$custom -lt 1024 -or [int]$custom -gt 65535) {
                    Write-Warn $L.PortInvalid; continue
                }
                $selected = $custom
            }
        }
        if (-not $selected) { Write-Warn $L.InvalidChoice; continue }

        if ($usedPorts -contains $selected) {
            $inst = Get-RegInstances | Where-Object { $_.Port -eq $selected } | Select-Object -First 1
            Write-Warn ($L.PortUsedByInstanceFmt -f $selected, $inst.ServiceName, $inst.InstallDir)
            if (-not (Confirm-Action $L.PortUseAnywayAsk)) { continue }
        }

        if (Test-PortBusy $selected) {
            Write-Warn ($L.PortIsBusyFmt -f $selected, (Get-PortOwner $selected))
            if (-not (Confirm-Action $L.PortUseAnywayAsk)) { continue }
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
    Write-Step ($L.DlGettingUrl -f $Bits)
    Write-Log "GET $url" 'INFO'
    try {
        $ProgressPreference = 'SilentlyContinue'
        $link = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15).Content.Trim()
        Write-Log "Server response: $link" 'INFO'
    } catch { throw ($L.DlFailedUrl -f $_.Exception.Message) }
    if ($link -notmatch '^https?://.+\.zip$') { throw ($L.DlUnexpected -f $link) }
    Write-OK ($L.DlDistribution -f (Split-Path $link -Leaf))
    return $link
}

function Download-Distrib([string]$Url, [string]$OutFile) {
    Write-Step $L.DlDownloading
    Write-Log "Download: $Url" 'INFO'
    $done = $false
    if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
        try {
            Start-BitsTransfer -Source $Url -Destination $OutFile -DisplayName 'Apache HTTP Server'
            $done = $true
        } catch {
            Write-Warn $L.DlBitsFailed
        }
    }
    if (-not $done) {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
    }
    if (-not (Test-Path $OutFile)) { throw ($L.DlNotSaved -f $OutFile) }
    $sizeMB = [math]::Round((Get-Item $OutFile).Length / 1MB, 1)
    Write-OK ($L.DlDownloaded -f $sizeMB)
}

# -----------------------------------------------
#  httpd.conf generator (Apache config — stays in English)
# -----------------------------------------------
function New-HttpdConf([string]$InstallDir, [string]$Port, [string]$ServiceName, [string]$Wsap24Path = '') {
    $srvRoot = $InstallDir.Replace('\', '/')

    $wsap24Block = ''
    if ($Wsap24Path) {
        $dll = $Wsap24Path.Replace('\', '/')
        $wsap24Block = @"

# 1C:Enterprise web server extension module
LoadModule _1cws_module "$dll"
"@
    }

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
LoadModule status_module       modules/mod_status.so$wsap24Block

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
#  index.html generator (UI language matches installer)
# -----------------------------------------------
function New-IndexHtml([string]$InstallDir, [string]$Port, [string]$ServiceName, [string]$LogFile) {
    $addr     = if ($Port -eq '80') { 'http://localhost' } else { "http://localhost:$Port" }
    $logName  = Split-Path $LogFile -Leaf
    $logPath  = $LogFile.Replace('\', '/')
    $htmlLang = $script:Lang

    return @"
<!DOCTYPE html><html lang="$htmlLang"><head>
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
  <h1>$($L.HtmlRunning)</h1>
  <p class="svc">$($L.HtmlServiceLabel): $ServiceName</p>
  <div class="badge"><div class="dot"></div>$($L.HtmlActive)</div>
  <div class="info">
    <div class="row"><span class="k">$($L.HtmlAddress)</span><span class="v"><a href="$addr">$addr</a></span></div>
    <div class="row"><span class="k">$($L.HtmlServiceLabel)</span><span class="v">$ServiceName</span></div>
    <div class="row"><span class="k">$($L.HtmlDirectory)</span><span class="v">$InstallDir\htdocs</span></div>
    <div class="row"><span class="k">$($L.HtmlConfig)</span><span class="v">$InstallDir\conf\httpd.conf</span></div>
    <div class="row"><span class="k">$($L.HtmlApacheLogs)</span><span class="v">$InstallDir\logs\</span></div>
    <div class="row"><span class="k">$($L.HtmlStatus)</span><span class="v"><a href="/server-status">server-status</a></span></div>
  </div>
  <div class="log-link">$($L.HtmlInstallLog): <a href="file:///$logPath">$logName</a></div>
</div></body></html>
"@
}

# -----------------------------------------------
#  Detect 1C platforms (both architectures)
# -----------------------------------------------
function Get-All1CPlatforms {
    $platforms = @{}
    $p64 = Find-1CPlatform -Bits 64
    $p32 = Find-1CPlatform -Bits 32
    if ($p64) { $platforms['64'] = $p64 }
    if ($p32) { $platforms['32'] = $p32 }
    return $platforms
}

# -----------------------------------------------
#  Apache bitness resolution (install flow)
#
#  Logic:
#    - No 1C found       -> Apache bits = OS bits, no wsap24
#    - Only one 1C bits  -> use it
#    - Both bits found   -> ask user
#    Within selected platform:
#      - wsap24 OK  -> ask "add to config?" (default yes)
#      - wsap24 missing AND 1C bits == OS bits -> warn, no integration
#      - wsap24 missing AND 1C bits != OS bits -> ask "match 1C or match OS?"
#  Returns: @{ Bits = <int>; Wsap24Path = <string-or-empty> }
# -----------------------------------------------
function Resolve-ApacheBitnessForInstall([int]$OsBits) {
    $platforms = Get-All1CPlatforms

    # Case 1: no 1C
    if ($platforms.Count -eq 0) {
        Write-Step ($L.C1Searching -f $OsBits)
        Write-Warn ($L.C1NotFound -f $OsBits)
        Write-Log "1C platform: not found at all" 'INFO'
        Write-OK ($L.BitnessByOs -f $OsBits)
        return @{ Bits = $OsBits; Wsap24Path = '' }
    }

    # Case 2: select platform
    $selected = $null
    if ($platforms.Count -eq 2) {
        Write-Host ""
        Write-Host ("  " + $L.C1FoundBoth) -ForegroundColor Cyan
        Write-Host ""
        Write-Host ("    [1] 1C $($platforms['32'].Version) (32-bit)  $($platforms['32'].Path)")
        Write-Host ("    [2] 1C $($platforms['64'].Version) (64-bit)  $($platforms['64'].Path)")
        Write-Host ""
        $c = Read-Choice -Prompt ($L.ChoicePromptN -f 2) -Default "1"
        Write-Log "1C platform choice: $c" 'INPUT'
        $selected = if ($c -eq '2') { $platforms['64'] } else { $platforms['32'] }
        $selectedBits = if ($c -eq '2') { 64 } else { 32 }
    } elseif ($platforms.ContainsKey('64')) {
        $selected = $platforms['64']
        $selectedBits = 64
    } else {
        $selected = $platforms['32']
        $selectedBits = 32
    }

    Write-OK ($L.C1Found -f $selected.Version)
    Write-Host ("    " + ($L.C1Path -f $selected.Path)) -ForegroundColor DarkGray
    Write-Log "1C selected: $($selected.Version) ($selectedBits-bit) at $($selected.Path)" 'INFO'

    # Case 3a: wsap24 OK
    if ($selected.Exists) {
        Write-OK ($L.C1WsapFound -f $selected.DllPath)
        Write-Log "wsap24.dll found: $($selected.DllPath)" 'OK'
        if (Confirm-Action $L.C1WsapAddPrompt $true) {
            Write-OK $L.C1WsapAdded
            Write-OK ($L.BitnessForInstall -f $selectedBits)
            return @{ Bits = $selectedBits; Wsap24Path = $selected.DllPath }
        } else {
            Write-Warn $L.C1WsapNotAdded
            Write-OK ($L.BitnessForInstall -f $selectedBits)
            return @{ Bits = $selectedBits; Wsap24Path = '' }
        }
    }

    # Case 3b: wsap24 missing, but 1C bits == OS bits -> no choice needed
    Write-Warn ($L.BitnessConflictMsg -f $selectedBits)
    Write-Warn ($L.C1WsapMissing -f $selected.DllPath)
    Write-Warn $L.C1WsapNoPub
    Write-Warn $L.C1WsapReinstall
    Write-Log "wsap24.dll: missing at $($selected.DllPath)" 'WARN'

    if ($selectedBits -eq $OsBits) {
        Write-OK ($L.BitnessForInstall -f $selectedBits)
        return @{ Bits = $selectedBits; Wsap24Path = '' }
    }

    # Case 3c: wsap24 missing AND 1C bits != OS bits -> give choice
    Write-Host ""
    Write-Host ("  " + $L.BitnessConflictHelp) -ForegroundColor Yellow
    Write-Host ""
    Write-Host ("  " + $L.BitnessOptions) -ForegroundColor Cyan
    Write-Host ("    " + ($L.BitnessOpt1C -f $selectedBits))
    Write-Host ("    " + ($L.BitnessOptOs -f $OsBits))
    Write-Host ""
    $c = Read-Choice -Prompt ($L.ChoicePromptN -f 2) -Default "1"
    Write-Log "Bitness conflict choice: $c (1=1C, 2=OS)" 'INPUT'

    if ($c -eq '2') {
        Write-OK ($L.BitnessForInstall -f $OsBits)
        return @{ Bits = $OsBits; Wsap24Path = '' }
    } else {
        Write-OK ($L.BitnessForInstall -f $selectedBits)
        return @{ Bits = $selectedBits; Wsap24Path = '' }
    }
}

# -----------------------------------------------
#  Wsap24 resolution for known bitness (change-bitness flow)
# -----------------------------------------------
function Resolve-Wsap24ForBitness([int]$Bits) {
    Write-Step ($L.C1Searching -f $Bits)
    $platform = Find-1CPlatform -Bits $Bits

    if (-not $platform) {
        Write-Warn ($L.C1NotFound -f $Bits)
        return ''
    }

    Write-OK ($L.C1Found -f $platform.Version)
    Write-Host ("    " + ($L.C1Path -f $platform.Path)) -ForegroundColor DarkGray

    if (-not $platform.Exists) {
        Write-Warn ($L.C1WsapMissing -f $platform.DllPath)
        Write-Warn $L.C1WsapNoPub
        Write-Warn $L.C1WsapReinstall
        return ''
    }

    Write-OK ($L.C1WsapFound -f $platform.DllPath)
    if (Confirm-Action $L.C1WsapAddPrompt $true) {
        Write-OK $L.C1WsapAdded
        return $platform.DllPath
    }
    Write-Warn $L.C1WsapNotAdded
    return ''
}

# -----------------------------------------------
#  Service "marked for deletion" detection
# -----------------------------------------------
function Test-ServiceLingering([string]$Name) {
    Start-Sleep -Milliseconds 500
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    return ($null -ne $svc)
}

# -----------------------------------------------
#  Detect Apache bitness from existing httpd.exe
# -----------------------------------------------
function Get-HttpdBitness([string]$HttpdExe) {
    if (-not (Test-Path $HttpdExe)) { return 0 }
    try {
        $fs = [System.IO.File]::OpenRead($HttpdExe)
        try {
            $br = New-Object System.IO.BinaryReader($fs)
            $fs.Seek(0x3C, 'Begin') | Out-Null
            $peOffset = $br.ReadInt32()
            $fs.Seek($peOffset + 4, 'Begin') | Out-Null
            $machine = $br.ReadUInt16()
            if ($machine -eq 0x8664) { return 64 }   # AMD64
            if ($machine -eq 0x014C) { return 32 }   # I386
            return 0
        } finally { $fs.Close() }
    } catch {
        Write-Log "Get-HttpdBitness error: $($_.Exception.Message)" 'WARN'
        return 0
    }
}

# -----------------------------------------------
#  Write both httpd.conf and index.html
# -----------------------------------------------
function Write-ConfigFiles {
    param(
        [string]$InstallDir,
        [string]$Port,
        [string]$ServiceName,
        [string]$Wsap24Path,
        [string]$LogFile
    )
    New-HttpdConf -InstallDir $InstallDir -Port $Port -ServiceName $ServiceName -Wsap24Path $Wsap24Path |
        Set-Content -Path "$InstallDir\conf\httpd.conf" -Encoding UTF8
    New-IndexHtml -InstallDir $InstallDir -Port $Port -ServiceName $ServiceName -LogFile $LogFile |
        Set-Content -Path "$InstallDir\htdocs\index.html" -Encoding UTF8
}

# -----------------------------------------------
#  HTTP verification + browser open (after success)
# -----------------------------------------------
function Invoke-VerifyAndOpen {
    param([string]$Port, [string]$InstallDir)

    Write-Header $L.HdrVerification
    $checkUrl = if ($Port -eq '80') { 'http://localhost' } else { "http://localhost:$Port" }
    Write-Step ($L.VerGet -f $checkUrl)
    Start-Sleep -Seconds 1

    $statusCode = 0
    try {
        $ProgressPreference = 'SilentlyContinue'
        $statusCode = (Invoke-WebRequest -Uri $checkUrl -UseBasicParsing -TimeoutSec 10).StatusCode
        Write-Log "HTTP response: $statusCode" 'INFO'
    } catch {
        Write-Log "HTTP check: $($_.Exception.Message)" 'WARN'
    }

    if ($statusCode -eq 200) {
        Write-OK $L.VerOk
    } else {
        Write-Warn ($L.VerWrongResponse -f $statusCode, "$InstallDir\logs\error_log")
    }

    Write-Step ($L.OpeningBrowser -f $checkUrl)
    Start-Sleep -Seconds 1
    Start-Process $checkUrl
}

# -----------------------------------------------
#  Success summary block (Done!)
# -----------------------------------------------
function Show-SuccessSummary {
    param(
        [string]$ServiceName,
        [string]$InstallDir,
        [string]$Port,
        [object]$FirewallEnabled = $null,   # $null = don't show line
        [string]$Wsap24Path = '',
        [string]$BackupPath = ''
    )
    Write-Header $L.HdrDone
    $url = if ($Port -eq '80') { 'http://localhost' } else { "http://localhost:$Port" }
    Write-Host ""
    Write-Host ("  $($L.SumAddress)  : $url")          -ForegroundColor Green
    Write-Host ("  $($L.SumService)  : $ServiceName")  -ForegroundColor Green
    Write-Host ("  $($L.SumFolder)   : $InstallDir")   -ForegroundColor Green
    if ($null -ne $FirewallEnabled) {
        $fwSummary = if ($FirewallEnabled) { $L.SumFwAdded } else { $L.SumFwNotConfigured }
        Write-Host ("  $($L.SumFirewall) : $fwSummary") -ForegroundColor Green
    }
    if ($Wsap24Path) {
        Write-Host ("  $($L.SumWsap)    : $Wsap24Path") -ForegroundColor Green
    }
    Write-Host ("  $($L.SumLog)      : $LOG_FILE")     -ForegroundColor DarkGray
    if ($BackupPath) { Write-Host ("  $($L.SumBackup)  : $BackupPath") -ForegroundColor DarkGray }
    Write-Host ""
    Write-Host ("  " + $L.SumServiceCommands)          -ForegroundColor DarkGray
    Write-Host "    Start-Service $ServiceName"        -ForegroundColor DarkGray
    Write-Host "    Stop-Service $ServiceName"         -ForegroundColor DarkGray
    Write-Host "    Restart-Service $ServiceName"      -ForegroundColor DarkGray
    Write-Host ""
}

# -----------------------------------------------
#  Instance picker (used by all change/remove actions)
# -----------------------------------------------
function Select-Instance {
    param([object[]]$Instances, [string]$Prompt = '')
    if ($Instances.Count -eq 0) { return $null }
    if (-not $Prompt) { $Prompt = $L.SelectInstancePrompt }

    if ($Instances.Count -eq 1) {
        $inst = $Instances[0]
        $addr = if ($inst.Port -eq '80') { 'http://localhost' } `
                elseif ($inst.Port -eq '?') { '-' } `
                else { "http://localhost:$($inst.Port)" }
        Write-Host ""
        Write-Host ("  $($inst.ServiceName)  $addr  $($inst.InstallDir)  [$($inst.Status)]") -ForegroundColor DarkCyan
        return $inst
    }

    Write-Host ""
    Write-Host ("  " + $Prompt) -ForegroundColor Cyan
    Write-Host ""
    for ($i = 0; $i -lt $Instances.Count; $i++) {
        $inst = $Instances[$i]
        $addr = if ($inst.Port -eq '80') { 'http://localhost' } `
                elseif ($inst.Port -eq '?') { '-' } `
                else { "http://localhost:$($inst.Port)" }
        Write-Host "    [$($i+1)] $($inst.ServiceName)  $addr  $($inst.InstallDir)  [$($inst.Status)]"
    }
    Write-Host ""
    $c = Read-Choice -Prompt ($L.ChoicePromptN -f $Instances.Count) -Default "1"
    Write-Log "Instance choice: $c" 'INPUT'
    if ($c -notmatch '^\d+$' -or [int]$c -lt 1 -or [int]$c -gt $Instances.Count) {
        Write-Warn $L.InvalidChoice
        return $null
    }
    return $Instances[[int]$c - 1]
}

# ===============================================
#  ACTION FLOWS
# ===============================================

# -----------------------------------------------
#  INSTALL (full new instance)
# -----------------------------------------------
function Invoke-InstallAction {
    # 1. OS bits
    Write-Header $L.HdrSystemDetection
    Write-Log "PROCESSOR_ARCHITECTURE: $env:PROCESSOR_ARCHITECTURE" 'INFO'
    $osBits = if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') { 64 } else { 32 }
    Write-OK ($L.OsDetected -f $osBits)

    # 2. 1C / wsap24 / Apache bitness
    Write-Header $L.Hdr1C
    $bitnessResult = Resolve-ApacheBitnessForInstall -OsBits $osBits
    $apacheBits = $bitnessResult.Bits
    $wsap24Path = $bitnessResult.Wsap24Path
    $addWsap24  = [bool]$wsap24Path

    # 3. VC++ check (using Apache bitness, not OS bitness!)
    Write-Header $L.HdrVCRedist
    Assert-VCRedist -Bits $apacheBits

    # 4. Folder
    Write-Header $L.HdrInstallFolder
    $installDir = Select-InstallDir
    Write-OK ($L.FolderResult -f $installDir)

    # 5. Port
    Write-Header $L.HdrPort
    $port = Select-Port
    Write-OK ($L.PortResult -f $port)

    # 6. Service name
    Write-Header $L.HdrServiceName
    $serviceName = Select-ServiceName -Port $port
    $fwRuleName  = Get-FwRuleName -Port $port
    Write-OK ($L.SvcResult -f $serviceName)

    # 7. Firewall preference
    Write-Header $L.HdrFirewall
    $openFirewall = Confirm-Action ($L.FwAskOpen -f $port) $true
    if ($openFirewall) { Write-OK $L.FwWillAdd } else { Write-Warn $L.FwWillSkip }
    Write-Log "Firewall preference: $openFirewall" 'INFO'

    # 8. Confirm parameters
    $wsapStatus = if ($addWsap24)        { $L.WsapAddShort } `
                  elseif ($wsap24Path)   { $L.WsapFoundSkipShort } `
                  else                   { $L.WsapNotAvailShort }
    $fwStatus   = if ($openFirewall)     { $L.FwOpenPortShort } else { $L.FwSkipShort }

    Write-Host ""
    Write-Host "  +------------------------------------------" -ForegroundColor Cyan
    Write-Host ("  | " + $L.BoxParams) -ForegroundColor Cyan
    Write-Host ("  |  $($L.BoxFolder)   : $installDir")
    Write-Host ("  |  $($L.BoxPort)     : $port")
    Write-Host ("  |  $($L.BoxService)  : $serviceName")
    Write-Host ("  |  $($L.BoxFirewall) : $fwStatus")
    Write-Host ("  |  $($L.BoxWsap)     : $wsapStatus")
    Write-Host ("  |  Apache       : " + ($L.OsValueShort -f $apacheBits))
    Write-Host ("  |  $($L.BoxOs)       : " + ($L.OsValueShort -f $osBits))
    Write-Host "  +------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Log "Params: service=$serviceName folder=$installDir port=$port apache=$apacheBits-bit os=$osBits-bit firewall=$openFirewall wsap24=$addWsap24" 'INFO'

    if (-not (Confirm-Action $L.AskStartInstall)) {
        Write-Step $L.Cancelled
        return $false
    }

    # 9. Disk space
    Write-Header $L.HdrDiskSpace
    Assert-DiskSpace -Path $installDir -RequiredMB $MIN_INSTALL_MB -Purpose $L.PurposeApache
    Assert-DiskSpace -Path $env:TEMP   -RequiredMB 30              -Purpose $L.PurposeTemp

    # 10. Backup + remove old
    Write-Header $L.HdrPrep
    $backupPath = $null

    if (Test-Path $installDir) {
        $freeForBackup = Get-FreeDiskSpaceMB -Path $WORK_DIR
        if ($freeForBackup -lt $MIN_BACKUP_MB) {
            Write-Warn ($L.BackupNoSpace -f $freeForBackup)
            if (-not (Confirm-Action $L.BackupContinueWithout)) { return $false }
        } else {
            $backupPath = Backup-Install -InstallDir $installDir
        }
        Remove-NamedService -Name $serviceName
        Write-Step ($L.PrepRemovingOld -f $installDir)
        Remove-Item -Path $installDir -Recurse -Force
        Write-OK $L.PrepOldRemoved
    } else {
        Remove-NamedService -Name $serviceName
    }

    # 11. Download + extract
    Write-Header $L.HdrDownload
    $distribUrl = Get-DistribUrl -Bits $apacheBits
    Download-Distrib -Url $distribUrl -OutFile $TEMP_ZIP

    Write-Header $L.HdrInstall
    Write-Step $L.InstExtracting
    if (Test-Path $TEMP_EXTRACT) { Remove-Item $TEMP_EXTRACT -Recurse -Force }

    try {
        Expand-Archive -Path $TEMP_ZIP -DestinationPath $TEMP_EXTRACT -Force
    } catch {
        Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
        throw ($L.InstExtractError -f $_.Exception.Message)
    }

    $httpdFound = Get-ChildItem -Path $TEMP_EXTRACT -Recurse -Filter 'httpd.exe' | Select-Object -First 1
    if (-not $httpdFound) {
        Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
        throw $L.InstHttpdNotInZip
    }

    $extracted = $httpdFound.Directory.Parent.FullName
    Write-Log "Distribution root: $extracted" 'INFO'

    try {
        Move-Item -Path $extracted -Destination $installDir -Force
    } catch {
        Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
        throw ($L.InstMoveError -f $_.Exception.Message)
    }

    Remove-Item $TEMP_ZIP     -Force -ErrorAction SilentlyContinue
    Remove-Item $TEMP_EXTRACT -Recurse -Force -ErrorAction SilentlyContinue
    Write-OK ($L.InstExtractedTo -f $installDir)

    # 12. Config files
    Write-Step $L.InstWritingConf
    try {
        Write-ConfigFiles -InstallDir $installDir -Port $port -ServiceName $serviceName -Wsap24Path $wsap24Path -LogFile $LOG_FILE
        if ($addWsap24) { Write-OK $L.InstConfDoneWsap } else { Write-OK $L.InstConfDone }
        Write-OK $L.InstHtmlDone
    } catch {
        Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
        throw ($L.InstConfError -f $_.Exception.Message)
    }

    # 13. Firewall
    Write-Header $L.HdrFirewall
    $httpdExe = "$installDir\bin\httpd.exe"
    if ($openFirewall) {
        Add-ApacheFirewallRule -RuleName $fwRuleName -HttpdExe $httpdExe -Port $port
    } else {
        Write-Warn $L.FwSkippedByUser
        Write-Log "Firewall: skipped by user" 'INFO'
    }

    # 14. Register and start service
    Write-Header $L.HdrService
    Write-Step ($L.SvcRegistering -f $serviceName)
    Write-Log "Run: $httpdExe -k install -n $serviceName" 'INFO'

    if (-not (Test-Path $httpdExe)) {
        Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
        throw ($L.SvcHttpdNotFound -f $httpdExe)
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
        throw (($L.SvcHttpdFailedCode -f $proc.ExitCode) + "`nstderr: $errTxt")
    }
    if (-not (Test-ServiceExists $serviceName)) {
        Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
        throw ($L.SvcNotInScm -f $serviceName)
    }
    Write-OK ($L.SvcRegistered -f $serviceName)

    Write-Step $L.SvcStarting
    try {
        Start-Service -Name $serviceName
        Start-Sleep -Seconds 3
    } catch {
        Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
        throw ($L.SvcStartError -f $_.Exception.Message)
    }

    if (-not (Test-ServiceRunning $serviceName)) {
        $apacheErr = if (Test-Path "$installDir\logs\error_log") {
            Get-Content "$installDir\logs\error_log" -Tail 15 | Out-String
        } else { "(not found)" }
        Write-Log "Service did not start. error_log:`n$apacheErr" 'ERROR'
        Invoke-Cleanup -InstallDir $installDir -ServiceName $serviceName -FwRule $fwRuleName
        throw (($L.SvcDidNotStart -f $serviceName) + "`n" + $L.SvcErrorLogLabel + "`n" + $apacheErr)
    }
    Write-OK ($L.SvcStarted -f $serviceName)

    # 15. Save to registry
    Save-RegInstance -ServiceName $serviceName -InstallDir $installDir -Port $port

    # 16. Show summary, verify, open
    Show-SuccessSummary -ServiceName $serviceName -InstallDir $installDir -Port $port `
        -FirewallEnabled $openFirewall -Wsap24Path $(if ($addWsap24) { $wsap24Path } else { '' }) `
        -BackupPath $backupPath
    Invoke-VerifyAndOpen -Port $port -InstallDir $installDir
    Write-Log "Installation complete: $serviceName" 'OK'
    return $true
}

# -----------------------------------------------
#  REMOVE
# -----------------------------------------------
function Invoke-RemoveAction {
    Write-Header $L.HdrRemoveInstance

    $installed = @(Get-InstalledApaches)
    $target = Select-Instance -Instances $installed -Prompt $L.RemSelectPrompt
    if (-not $target) { return $false }

    $fwRule = Get-FwRuleName -Port $target.Port

    Write-Host ""
    Write-Host ("  " + $L.RemWillRemove) -ForegroundColor Yellow
    Write-Host ("    $($L.BoxService) : $($target.ServiceName)") -ForegroundColor Yellow
    Write-Host ("    $($L.BoxFolder) : $($target.InstallDir)")    -ForegroundColor Yellow
    Write-Host ("    $($L.BoxPort) : $($target.Port)")             -ForegroundColor Yellow
    Write-Host ""

    if (-not (Confirm-Action $L.RemAskConfirm)) {
        Write-Step $L.Cancelled
        return $false
    }

    # Backup
    if (Test-Path $target.InstallDir) {
        $freeForBackup = Get-FreeDiskSpaceMB -Path $WORK_DIR
        if ($freeForBackup -lt $MIN_BACKUP_MB) {
            Write-Warn ($L.BackupNoSpace -f $freeForBackup)
        } else {
            $backupResult = Backup-Install -InstallDir $target.InstallDir
            if ($backupResult) { Write-OK ($L.BackupSaved -f $backupResult) }
        }
    }

    # Stop and remove service
    Remove-NamedService -Name $target.ServiceName
    Remove-RegInstance -ServiceName $target.ServiceName

    # Ask about firewall rule (default: yes - sensible cleanup)
    $fwExists = $null -ne (Get-NetFirewallRule -DisplayName $fwRule -ErrorAction SilentlyContinue)
    if ($fwExists) {
        if (Confirm-Action ($L.RemFwAsk -f $target.Port) $true) {
            Remove-ApacheFirewallRule -RuleName $fwRule
            Write-OK $L.RemFwRemoved
        } else {
            Write-Warn $L.RemFwKept
        }
    }

    # Remove folder
    if (Test-Path $target.InstallDir) {
        Write-Step ($L.RemFolderRemoving -f $target.InstallDir)
        try {
            Remove-Item -Path $target.InstallDir -Recurse -Force
            Write-OK $L.RemFolderRemoved
            Write-Log "Folder $($target.InstallDir) removed" 'OK'
        } catch {
            Write-Fail ($L.RemFolderError -f $_.Exception.Message)
        }
    }

    Write-OK ($L.RemDone -f $target.ServiceName)
    Write-Log "Remove complete: $($target.ServiceName)" 'OK'
    return $true
}

# -----------------------------------------------
#  CHANGE PORT
# -----------------------------------------------
function Invoke-ChangePortAction {
    Write-Header $L.HdrChangePort

    $installed = @(Get-InstalledApaches | Where-Object { $_.Source -eq 'registry' })
    if ($installed.Count -eq 0) {
        Write-Warn $L.NoInstancesForAction
        return $false
    }

    $target = Select-Instance -Instances $installed
    if (-not $target) { return $false }

    Write-Host ""
    Write-Host ("  " + ($L.ChPortCurrent -f $target.Port)) -ForegroundColor Cyan

    # Pick new port
    Write-Host ""
    Write-Host ("  " + $L.ChPortSelectNew) -ForegroundColor Cyan
    $newPort = Select-Port
    if ($newPort -eq $target.Port) {
        Write-Warn $L.ChPortSameError
        return $false
    }

    if (-not (Confirm-Action ($L.ChPortConfirm -f $target.Port, $newPort))) {
        Write-Step $L.Cancelled
        return $false
    }

    Write-Step ($L.ChPortApplying -f $target.Port, $newPort)
    Write-Log "ChangePort: $($target.ServiceName) $($target.Port) -> $newPort" 'INFO'

    # Detect existing wsap24 from current httpd.conf to preserve it
    $existingWsap = ''
    $confPath = Join-Path $target.InstallDir 'conf\httpd.conf'
    if (Test-Path $confPath) {
        $m = Select-String -Path $confPath -Pattern '^LoadModule\s+_1cws_module\s+"([^"]+)"' |
             Select-Object -First 1
        if ($m) { $existingWsap = $m.Matches[0].Groups[1].Value -replace '/', '\' }
    }

    # Stop service
    Write-Step $L.ChPortStopping
    Stop-NamedService -Name $target.ServiceName

    # Update config files
    Write-Step $L.ChPortUpdConf
    Write-ConfigFiles -InstallDir $target.InstallDir -Port $newPort -ServiceName $target.ServiceName `
        -Wsap24Path $existingWsap -LogFile $LOG_FILE
    Write-OK $L.InstConfDone
    Write-OK $L.InstHtmlDone

    # Firewall
    $oldFw = Get-FwRuleName -Port $target.Port
    $newFw = Get-FwRuleName -Port $newPort
    Write-Step $L.ChPortUpdFw
    Remove-ApacheFirewallRule -RuleName $oldFw
    if (Confirm-Action ($L.ChPortAddNewFwAsk -f $newPort) $true) {
        Add-ApacheFirewallRule -RuleName $newFw -HttpdExe "$($target.InstallDir)\bin\httpd.exe" -Port $newPort
    } else {
        Write-Warn $L.FwSkippedByUser
    }

    # Update registry
    Save-RegInstance -ServiceName $target.ServiceName -InstallDir $target.InstallDir -Port $newPort

    # Start
    Write-Step $L.ChPortRestarting
    try {
        Start-Service -Name $target.ServiceName
        Start-Sleep -Seconds 3
    } catch {
        throw ($L.SvcStartError -f $_.Exception.Message)
    }
    if (-not (Test-ServiceRunning $target.ServiceName)) {
        throw ($L.SvcDidNotStart -f $target.ServiceName)
    }
    Write-OK ($L.SvcStarted -f $target.ServiceName)
    Write-OK ($L.ChPortChanged -f $target.Port, $newPort)
    Write-Log "ChangePort done: $($target.ServiceName) $($target.Port) -> $newPort" 'OK'

    Show-SuccessSummary -ServiceName $target.ServiceName -InstallDir $target.InstallDir -Port $newPort `
        -Wsap24Path $existingWsap
    Invoke-VerifyAndOpen -Port $newPort -InstallDir $target.InstallDir
    return $true
}

# -----------------------------------------------
#  CHANGE SERVICE NAME
# -----------------------------------------------
function Invoke-ChangeNameAction {
    Write-Header $L.HdrChangeName

    $installed = @(Get-InstalledApaches | Where-Object { $_.Source -eq 'registry' })
    if ($installed.Count -eq 0) {
        Write-Warn $L.NoInstancesForAction
        return $false
    }

    $target = Select-Instance -Instances $installed
    if (-not $target) { return $false }

    Write-Host ""
    Write-Host ("  " + ($L.ChSvcCurrent -f $target.ServiceName)) -ForegroundColor Cyan
    Write-Host ""

    # Get new name (validate, ensure not the same, ensure not taken in SCM)
    $newName = $null
    while ($true) {
        $candidate = (Read-Host ("  " + $L.ChSvcEnterNew)).Trim()
        if ([string]::IsNullOrEmpty($candidate)) { Write-Warn $L.SvcEmptyName; continue }
        if ($candidate -match '\s')              { Write-Warn $L.SvcNameSpaces; continue }
        if ($candidate -notmatch '^[A-Za-z0-9_.\-]+$') { Write-Warn $L.SvcNameChars; continue }
        if ($candidate -eq $target.ServiceName)  { Write-Warn $L.ChSvcSameError; continue }
        if (Test-ServiceExists $candidate)       { Write-Warn ($L.SvcNameTaken -f $candidate); continue }
        $newName = $candidate
        break
    }

    if (-not (Confirm-Action ($L.ChSvcConfirm -f $target.ServiceName, $newName))) {
        Write-Step $L.Cancelled
        return $false
    }

    Write-Step ($L.ChSvcApplying -f $target.ServiceName, $newName)
    Write-Log "ChangeName: $($target.ServiceName) -> $newName" 'INFO'

    # Detect existing wsap24
    $existingWsap = ''
    $confPath = Join-Path $target.InstallDir 'conf\httpd.conf'
    if (Test-Path $confPath) {
        $m = Select-String -Path $confPath -Pattern '^LoadModule\s+_1cws_module\s+"([^"]+)"' |
             Select-Object -First 1
        if ($m) { $existingWsap = $m.Matches[0].Groups[1].Value -replace '/', '\' }
    }

    # Stop and uninstall old service via httpd.exe (preserves SCM cleanly)
    $httpdExe = "$($target.InstallDir)\bin\httpd.exe"
    Write-Step ($L.ChSvcUninstalling -f $target.ServiceName)
    Stop-NamedService -Name $target.ServiceName
    if (Test-Path $httpdExe) {
        Start-Process -FilePath $httpdExe -ArgumentList '-k','uninstall','-n',$target.ServiceName `
            -Wait -NoNewWindow -ErrorAction SilentlyContinue
    } else {
        sc.exe delete $target.ServiceName 2>&1 | Out-Null
    }
    Start-Sleep -Seconds 1

    $oldLingering = Test-ServiceLingering -Name $target.ServiceName

    # Install new service
    Write-Step ($L.ChSvcInstallingNew -f $newName)
    $stdOut = Join-Path $env:TEMP 'httpd-stdout.txt'
    $stdErr = Join-Path $env:TEMP 'httpd-stderr.txt'
    $proc = Start-Process -FilePath $httpdExe -ArgumentList '-k','install','-n',$newName `
        -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdOut -RedirectStandardError $stdErr
    $errTxt = if (Test-Path $stdErr) { Get-Content $stdErr -Raw } else { '' }
    Remove-Item $stdOut,$stdErr -Force -ErrorAction SilentlyContinue
    if ($proc.ExitCode -ne 0 -or -not (Test-ServiceExists $newName)) {
        throw (($L.SvcHttpdFailedCode -f $proc.ExitCode) + "`nstderr: $errTxt")
    }
    Write-OK ($L.SvcRegistered -f $newName)

    # Update registry: drop old key, save new
    Remove-RegInstance -ServiceName $target.ServiceName
    Save-RegInstance -ServiceName $newName -InstallDir $target.InstallDir -Port $target.Port

    # Regenerate config files (httpd.conf comment + index.html show service name)
    Write-Step $L.ChPortUpdConf
    Write-ConfigFiles -InstallDir $target.InstallDir -Port $target.Port -ServiceName $newName `
        -Wsap24Path $existingWsap -LogFile $LOG_FILE
    Write-OK $L.InstConfDone
    Write-OK $L.InstHtmlDone

    # Start new service
    Write-Step $L.ChPortRestarting
    try {
        Start-Service -Name $newName
        Start-Sleep -Seconds 3
    } catch {
        throw ($L.SvcStartError -f $_.Exception.Message)
    }
    if (-not (Test-ServiceRunning $newName)) {
        throw ($L.SvcDidNotStart -f $newName)
    }
    Write-OK ($L.SvcStarted -f $newName)
    Write-OK ($L.ChSvcChanged -f $target.ServiceName, $newName)
    Write-Log "ChangeName done: $($target.ServiceName) -> $newName" 'OK'

    if ($oldLingering) {
        Write-Warn $L.ChSvcOldLingering
        Write-Log "Old service '$($target.ServiceName)' still in SCM (marked for deletion)" 'WARN'
    }

    Show-SuccessSummary -ServiceName $newName -InstallDir $target.InstallDir -Port $target.Port `
        -Wsap24Path $existingWsap
    Invoke-VerifyAndOpen -Port $target.Port -InstallDir $target.InstallDir
    return $true
}

# -----------------------------------------------
#  CHANGE BITNESS
# -----------------------------------------------
function Invoke-ChangeBitnessAction {
    Write-Header $L.HdrChangeBitness

    $installed = @(Get-InstalledApaches | Where-Object { $_.Source -eq 'registry' })
    if ($installed.Count -eq 0) {
        Write-Warn $L.NoInstancesForAction
        return $false
    }

    $target = Select-Instance -Instances $installed
    if (-not $target) { return $false }

    $httpdExe = "$($target.InstallDir)\bin\httpd.exe"
    $currentBits = Get-HttpdBitness -HttpdExe $httpdExe
    if ($currentBits -eq 0) {
        Write-Fail ($L.SvcHttpdNotFound -f $httpdExe)
        return $false
    }

    $newBits = if ($currentBits -eq 64) { 32 } else { 64 }

    Write-Host ""
    Write-Host ("  " + ($L.ChBitsCurrent -f $currentBits)) -ForegroundColor Cyan
    Write-Host ("  " + ($L.ChBitsTarget -f $newBits))      -ForegroundColor Cyan

    # Re-check 1C / wsap24 for new bitness
    Write-Header $L.Hdr1C
    $newWsap24 = Resolve-Wsap24ForBitness -Bits $newBits

    # Re-check VC++ for new bitness
    Write-Header $L.HdrVCRedist
    Assert-VCRedist -Bits $newBits

    if (-not (Confirm-Action ($L.ChBitsConfirm -f $currentBits, $newBits))) {
        Write-Step $L.Cancelled
        return $false
    }

    Write-Step ($L.ChBitsApplying -f $currentBits, $newBits)
    Write-Log "ChangeBitness: $($target.ServiceName) $currentBits -> $newBits" 'INFO'

    # Backup
    Write-Header $L.HdrPrep
    $backupPath = $null
    $freeForBackup = Get-FreeDiskSpaceMB -Path $WORK_DIR
    if ($freeForBackup -ge $MIN_BACKUP_MB) {
        $backupPath = Backup-Install -InstallDir $target.InstallDir
    }

    # Stop and uninstall service
    Write-Step ($L.ChSvcUninstalling -f $target.ServiceName)
    Stop-NamedService -Name $target.ServiceName
    if (Test-Path $httpdExe) {
        Start-Process -FilePath $httpdExe -ArgumentList '-k','uninstall','-n',$target.ServiceName `
            -Wait -NoNewWindow -ErrorAction SilentlyContinue
    } else {
        sc.exe delete $target.ServiceName 2>&1 | Out-Null
    }
    Start-Sleep -Seconds 1

    # Download new bitness
    Write-Header $L.HdrDownload
    $distribUrl = Get-DistribUrl -Bits $newBits
    Download-Distrib -Url $distribUrl -OutFile $TEMP_ZIP

    # Extract to temp
    Write-Header $L.HdrInstall
    Write-Step $L.InstExtracting
    if (Test-Path $TEMP_EXTRACT) { Remove-Item $TEMP_EXTRACT -Recurse -Force }
    try {
        Expand-Archive -Path $TEMP_ZIP -DestinationPath $TEMP_EXTRACT -Force
    } catch {
        throw ($L.InstExtractError -f $_.Exception.Message)
    }
    $httpdFound = Get-ChildItem -Path $TEMP_EXTRACT -Recurse -Filter 'httpd.exe' | Select-Object -First 1
    if (-not $httpdFound) {
        throw $L.InstHttpdNotInZip
    }
    $extracted = $httpdFound.Directory.Parent.FullName

    # Replace binaries: keep conf/, htdocs/, logs/
    Write-Step $L.ChBitsKeepUserFiles
    Write-Step $L.ChBitsCleaningOld
    Get-ChildItem -Path $target.InstallDir -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @('conf','htdocs','logs') } |
        ForEach-Object {
            try {
                if ($_.PSIsContainer) {
                    Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop
                } else {
                    Remove-Item $_.FullName -Force -ErrorAction Stop
                }
            } catch {
                Write-Log "Could not remove $($_.FullName): $($_.Exception.Message)" 'WARN'
            }
        }

    Write-Step $L.ChBitsExtractingNew
    Get-ChildItem -Path $extracted -Force | ForEach-Object {
        $dst = Join-Path $target.InstallDir $_.Name
        if ($_.Name -in @('conf','htdocs','logs')) {
            # Keep user data; don't overwrite
            if (-not (Test-Path $dst)) {
                Copy-Item $_.FullName -Destination $dst -Recurse -Force
            }
        } else {
            Copy-Item $_.FullName -Destination $dst -Recurse -Force
        }
    }

    Remove-Item $TEMP_ZIP     -Force -ErrorAction SilentlyContinue
    Remove-Item $TEMP_EXTRACT -Recurse -Force -ErrorAction SilentlyContinue
    Write-OK ($L.InstExtractedTo -f $target.InstallDir)

    # Regenerate config (wsap24 may have changed)
    Write-Step $L.ChPortUpdConf
    Write-ConfigFiles -InstallDir $target.InstallDir -Port $target.Port -ServiceName $target.ServiceName `
        -Wsap24Path $newWsap24 -LogFile $LOG_FILE
    if ($newWsap24) { Write-OK $L.InstConfDoneWsap } else { Write-OK $L.InstConfDone }
    Write-OK $L.InstHtmlDone

    # Reinstall service with same name
    Write-Step ($L.SvcRegistering -f $target.ServiceName)
    $stdOut = Join-Path $env:TEMP 'httpd-stdout.txt'
    $stdErr = Join-Path $env:TEMP 'httpd-stderr.txt'
    $proc = Start-Process -FilePath $httpdExe -ArgumentList '-k','install','-n',$target.ServiceName `
        -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdOut -RedirectStandardError $stdErr
    $errTxt = if (Test-Path $stdErr) { Get-Content $stdErr -Raw } else { '' }
    Remove-Item $stdOut,$stdErr -Force -ErrorAction SilentlyContinue
    if ($proc.ExitCode -ne 0 -or -not (Test-ServiceExists $target.ServiceName)) {
        throw (($L.SvcHttpdFailedCode -f $proc.ExitCode) + "`nstderr: $errTxt")
    }
    Write-OK ($L.SvcRegistered -f $target.ServiceName)

    # Start
    try {
        Start-Service -Name $target.ServiceName
        Start-Sleep -Seconds 3
    } catch {
        throw ($L.SvcStartError -f $_.Exception.Message)
    }
    if (-not (Test-ServiceRunning $target.ServiceName)) {
        $apacheErr = if (Test-Path "$($target.InstallDir)\logs\error_log") {
            Get-Content "$($target.InstallDir)\logs\error_log" -Tail 15 | Out-String
        } else { "(not found)" }
        throw (($L.SvcDidNotStart -f $target.ServiceName) + "`n" + $L.SvcErrorLogLabel + "`n" + $apacheErr)
    }
    Write-OK ($L.SvcStarted -f $target.ServiceName)
    Write-OK ($L.ChBitsChanged -f $currentBits, $newBits)
    Write-Log "ChangeBitness done: $($target.ServiceName) $currentBits -> $newBits" 'OK'

    Show-SuccessSummary -ServiceName $target.ServiceName -InstallDir $target.InstallDir -Port $target.Port `
        -Wsap24Path $newWsap24 -BackupPath $backupPath
    Invoke-VerifyAndOpen -Port $target.Port -InstallDir $target.InstallDir
    return $true
}

# ===============================================
#  MAIN
# ===============================================

Write-Log "==========================================" 'INFO'
Write-Log "Starting install-apache" 'INFO'
Write-Log "WorkDir: $WORK_DIR | IsExe: $isExe | UI lang: $script:Lang" 'INFO'
Write-Log "User: $env:USERNAME  Machine: $env:COMPUTERNAME" 'INFO'
Write-Log "PowerShell: $($PSVersionTable.PSVersion)  PSUICulture: $PSUICulture" 'INFO'
Write-Log "==========================================" 'INFO'

Clear-Host

# Main loop: stays in menu until user picks Exit
$firstIteration = $true
while ($true) {
    if ($firstIteration) {
        $firstIteration = $false
    } else {
        Write-Host ""
        Write-Host "  --------------------------------------------" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ("    " + $L.BannerTitle)    -ForegroundColor Cyan
    Write-Host ("    " + $L.BannerSubtitle) -ForegroundColor DarkGray
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  $($L.LabelLog): $LOG_FILE") -ForegroundColor DarkGray

    # Show installed instances
    $currentInstances = @(Get-InstalledApaches)
    if ($currentInstances.Count -gt 0) {
        Write-Host ""
        Write-Host ("  " + $L.InstalledInstances) -ForegroundColor DarkCyan
        foreach ($inst in $currentInstances) {
            $addr = if ($inst.Port -eq '80') { 'http://localhost' } `
                    elseif ($inst.Port -eq '?') { '-' } `
                    else { "http://localhost:$($inst.Port)" }
            Write-Host "    $($inst.ServiceName)  $addr  $($inst.InstallDir)  [$($inst.Status)]" -ForegroundColor DarkGray
        }
    }

    # Build menu dynamically
    Write-Host ""
    Write-Host ("  " + $L.MainMenuPrompt) -ForegroundColor Cyan
    Write-Host ""

    $hasInstances = $currentInstances.Count -gt 0
    $menuMap = @{}   # number -> action
    $idx     = 1

    Write-Host ("    [$idx] " + $L.MainMenuInstall)
    $menuMap[[string]$idx] = 'install'; $idx++

    if ($hasInstances) {
        Write-Host ("    [$idx] " + $L.MainMenuRemove)
        $menuMap[[string]$idx] = 'remove'; $idx++
        Write-Host ("    [$idx] " + $L.MainMenuChangePort)
        $menuMap[[string]$idx] = 'changeport'; $idx++
        Write-Host ("    [$idx] " + $L.MainMenuChangeName)
        $menuMap[[string]$idx] = 'changename'; $idx++
        Write-Host ("    [$idx] " + $L.MainMenuChangeBitness)
        $menuMap[[string]$idx] = 'changebitness'; $idx++
    } else {
        Write-Host ("    [$idx] " + $L.MainMenuRemoveDisabled) -ForegroundColor DarkGray
        $idx++   # number is shown but not selectable
    }

    Write-Host ("    [$idx] " + $L.MainMenuExit)
    $menuMap[[string]$idx] = 'exit'
    $maxChoice = $idx

    Write-Host ""

    $defaultChoice = if ($firstIteration -or -not $hasInstances) { '1' } else { [string]$maxChoice }
    # ^ on subsequent iterations after action, default is Exit
    $mainChoice = ''
    while (-not $menuMap.ContainsKey($mainChoice)) {
        $mainChoice = Read-Choice -Prompt ($L.ChoicePromptN -f $maxChoice) -Default $defaultChoice
        if (-not $menuMap.ContainsKey($mainChoice)) {
            Write-Warn $L.InvalidChoice
        }
    }
    $action = $menuMap[$mainChoice]
    Write-Log "Main menu: $mainChoice -> $action" 'INPUT'

    if ($action -eq 'exit') {
        Write-Step $L.ExitMsg
        Write-Log "User selected Exit" 'INFO'
        break
    }

    try {
        switch ($action) {
            'install'       { [void](Invoke-InstallAction) }
            'remove'        { [void](Invoke-RemoveAction) }
            'changeport'    { [void](Invoke-ChangePortAction) }
            'changename'    { [void](Invoke-ChangeNameAction) }
            'changebitness' { [void](Invoke-ChangeBitnessAction) }
        }
    } catch {
        # Action-level error: log, show, but stay in main loop
        $errMsg  = $_.Exception.Message
        $errLine = $_.InvocationInfo.ScriptLineNumber
        Write-Log "Action '$action' failed at line $errLine : $errMsg" 'ERROR'
        Write-Log "Stack: $($_.ScriptStackTrace)" 'ERROR'
        Write-Fail ($L.ErrAtLine -f $errLine, $errMsg)
        Write-Fail ($L.ErrLogPath -f $LOG_FILE)
    }

    # Pause before redrawing menu so the user can read the result
    Write-Host ""
    $null = Read-Host ("  " + $L.PressEnterToContinue)
}

Write-Log "==========================================" 'INFO'
Write-Log "Session complete" 'OK'
Write-Log "==========================================" 'INFO'
