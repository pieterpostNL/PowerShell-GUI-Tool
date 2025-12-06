#Requires -Version 5.1

<#
.SYNOPSIS
    PowerShell GUI Tool - One-Line Installer
.DESCRIPTION
    Een moderne GUI tool die gestart kan worden met: irm <url> | iex
.NOTES
    Auteur: PowerShell GUI Tool
    Repository: https://github.com/pieterpostNL/PowerShell-GUI-Tool
#>

# Check of we in Windows zijn
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "Deze tool vereist PowerShell 5.1 of hoger"
    exit
}

# Assemblies laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Functie voor het tonen van meldingen
function Show-Notification {
    param(
        [string]$Message,
        [string]$Title = 'Melding',
        [string]$Type = 'Information'
    )
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, 'OK', $Type)
}

# Functie voor systeem informatie
function Get-SystemInfo {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        $bios = Get-CimInstance Win32_BIOS
        
        $info = @"
╔══════════════════════════════════════╗
║        SYSTEEM INFORMATIE           ║
╚══════════════════════════════════════╝

🖥️  Computer:    $($cs.Name)
👤  Gebruiker:   $env:USERNAME
🏢  Domein:      $($cs.Domain)

💿  OS:          $($os.Caption)
📌  Versie:      $($os.Version)
🏗️  Build:       $($os.BuildNumber)
📦  Architectuur: $($os.OSArchitecture)

⚡  PowerShell:  $($PSVersionTable.PSVersion)
🔧  Fabrikant:   $($cs.Manufacturer)
📱  Model:       $($cs.Model)
🆔  Serial:      $($bios.SerialNumber)

💾  RAM:         $([math]::Round($cs.TotalPhysicalMemory/1GB, 2)) GB
🖥️  Processors:  $($cs.NumberOfProcessors)
🔢  Cores:       $($cs.NumberOfLogicalProcessors)

🕐  Opstarttijd: $($os.LastBootUpTime)
⏱️  Uptime:      $((Get-Date) - $os.LastBootUpTime | Select-Object -ExpandProperty Days) dagen
"@
        return $info
    }
    catch {
        return "❌ Fout bij ophalen systeem informatie: $($_.Exception.Message)"
    }
}

# Functie voor disk informatie
function Get-DiskInfo {
    try {
        $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
        $info = @"
╔══════════════════════════════════════╗
║         SCHIJF INFORMATIE           ║
╚══════════════════════════════════════╝

"@
        foreach ($disk in $disks) {
            $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
            $totalGB = [math]::Round($disk.Size/1GB, 2)
            $usedGB = $totalGB - $freeGB
            $pctUsed = [math]::Round(($usedGB/$totalGB)*100, 1)
            
            $info += @"
💿 Schijf $($disk.DeviceID)
   Totaal:  $totalGB GB
   Gebruikt: $usedGB GB ($pctUsed%)
   Vrij:    $freeGB GB
   Label:   $($disk.VolumeName)

"@
        }
        return $info
    }
    catch {
        return "❌ Fout bij ophalen schijf informatie: $($_.Exception.Message)"
    }
}

# Functie voor netwerk informatie
function Get-NetworkInfo {
    try {
        $adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
        $info = @"
╔══════════════════════════════════════╗
║        NETWERK INFORMATIE           ║
╚══════════════════════════════════════╝

"@
        foreach ($adapter in $adapters) {
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            $info += @"
🌐 $($adapter.Name)
   Status:      $($adapter.Status)
   Snelheid:    $($adapter.LinkSpeed)
   MAC:         $($adapter.MacAddress)
   IP:          $($ipConfig.IPAddress)

"@
        }
        return $info
    }
    catch {
        return "❌ Fout bij ophalen netwerk informatie: $($_.Exception.Message)"
    }
}

# Maak het hoofdvenster
$form = New-Object System.Windows.Forms.Form
$form.Text = 'PowerShell GUI Tool v1.0'
$form.Size = New-Object System.Drawing.Size(600, 550)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::White

# Header panel
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(600, 80)
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$form.Controls.Add($headerPanel)

# Titel label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titleLabel.Size = New-Object System.Drawing.Size(560, 30)
$titleLabel.Text = '⚡ PowerShell GUI Tool'
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$headerPanel.Controls.Add($titleLabel)

# Beschrijving label
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Location = New-Object System.Drawing.Point(20, 45)
$descLabel.Size = New-Object System.Drawing.Size(560, 25)
$descLabel.Text = 'One-line installeerbare PowerShell tool voor systeem informatie'
$descLabel.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
$headerPanel.Controls.Add($descLabel)

# Tab Control
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 90)
$tabControl.Size = New-Object System.Drawing.Size(570, 360)
$form.Controls.Add($tabControl)

# Tab 1: Systeem Info
$tab1 = New-Object System.Windows.Forms.TabPage
$tab1.Text = '🖥️ Systeem'
$tabControl.Controls.Add($tab1)

$systemInfoBox = New-Object System.Windows.Forms.TextBox
$systemInfoBox.Location = New-Object System.Drawing.Point(10, 10)
$systemInfoBox.Size = New-Object System.Drawing.Size(545, 240)
$systemInfoBox.Multiline = $true
$systemInfoBox.ScrollBars = 'Vertical'
$systemInfoBox.Font = New-Object System.Drawing.Font('Consolas', 9)
$systemInfoBox.ReadOnly = $true
$tab1.Controls.Add($systemInfoBox)

$btnSystemInfo = New-Object System.Windows.Forms.Button
$btnSystemInfo.Location = New-Object System.Drawing.Point(10, 260)
$btnSystemInfo.Size = New-Object System.Drawing.Size(170, 40)
$btnSystemInfo.Text = '🔄 Ververs Systeem Info'
$btnSystemInfo.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnSystemInfo.ForeColor = [System.Drawing.Color]::White
$btnSystemInfo.FlatStyle = 'Flat'
$btnSystemInfo.Add_Click({
    $systemInfoBox.Text = "Bezig met laden..."
    $systemInfoBox.Text = Get-SystemInfo
})
$tab1.Controls.Add($btnSystemInfo)

$btnDiskInfo = New-Object System.Windows.Forms.Button
$btnDiskInfo.Location = New-Object System.Drawing.Point(190, 260)
$btnDiskInfo.Size = New-Object System.Drawing.Size(170, 40)
$btnDiskInfo.Text = '💾 Schijf Informatie'
$btnDiskInfo.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnDiskInfo.ForeColor = [System.Drawing.Color]::White
$btnDiskInfo.FlatStyle = 'Flat'
$btnDiskInfo.Add_Click({
    $systemInfoBox.Text = "Bezig met laden..."
    $systemInfoBox.Text = Get-DiskInfo
})
$tab1.Controls.Add($btnDiskInfo)

$btnNetworkInfo = New-Object System.Windows.Forms.Button
$btnNetworkInfo.Location = New-Object System.Drawing.Point(370, 260)
$btnNetworkInfo.Size = New-Object System.Drawing.Size(170, 40)
$btnNetworkInfo.Text = '🌐 Netwerk Info'
$btnNetworkInfo.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnNetworkInfo.ForeColor = [System.Drawing.Color]::White
$btnNetworkInfo.FlatStyle = 'Flat'
$btnNetworkInfo.Add_Click({
    $systemInfoBox.Text = "Bezig met laden..."
    $systemInfoBox.Text = Get-NetworkInfo
})
$tab1.Controls.Add($btnNetworkInfo)

# Tab 2: Tools
$tab2 = New-Object System.Windows.Forms.TabPage
$tab2.Text = '🔧 Tools'
$tabControl.Controls.Add($tab2)

$toolsLabel = New-Object System.Windows.Forms.Label
$toolsLabel.Location = New-Object System.Drawing.Point(10, 10)
$toolsLabel.Size = New-Object System.Drawing.Size(545, 25)
$toolsLabel.Text = 'Handige systeem tools:'
$toolsLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$tab2.Controls.Add($toolsLabel)

$toolsOutputBox = New-Object System.Windows.Forms.TextBox
$toolsOutputBox.Location = New-Object System.Drawing.Point(10, 180)
$toolsOutputBox.Size = New-Object System.Drawing.Size(545, 120)
$toolsOutputBox.Multiline = $true
$toolsOutputBox.ScrollBars = 'Vertical'
$toolsOutputBox.Font = New-Object System.Drawing.Font('Consolas', 9)
$toolsOutputBox.ReadOnly = $true
$tab2.Controls.Add($toolsOutputBox)

# Tool buttons
$btnTaskMgr = New-Object System.Windows.Forms.Button
$btnTaskMgr.Location = New-Object System.Drawing.Point(10, 50)
$btnTaskMgr.Size = New-Object System.Drawing.Size(170, 35)
$btnTaskMgr.Text = '📊 Taakbeheer'
$btnTaskMgr.Add_Click({ Start-Process taskmgr })
$tab2.Controls.Add($btnTaskMgr)

$btnDevMgr = New-Object System.Windows.Forms.Button
$btnDevMgr.Location = New-Object System.Drawing.Point(190, 50)
$btnDevMgr.Size = New-Object System.Drawing.Size(170, 35)
$btnDevMgr.Text = '🔌 Apparaatbeheer'
$btnDevMgr.Add_Click({ Start-Process devmgmt.msc })
$tab2.Controls.Add($btnDevMgr)

$btnServices = New-Object System.Windows.Forms.Button
$btnServices.Location = New-Object System.Drawing.Point(370, 50)
$btnServices.Size = New-Object System.Drawing.Size(170, 35)
$btnServices.Text = '⚙️ Services'
$btnServices.Add_Click({ Start-Process services.msc })
$tab2.Controls.Add($btnServices)

$btnRegedit = New-Object System.Windows.Forms.Button
$btnRegedit.Location = New-Object System.Drawing.Point(10, 95)
$btnRegedit.Size = New-Object System.Drawing.Size(170, 35)
$btnRegedit.Text = '📝 Register-editor'
$btnRegedit.Add_Click({ Start-Process regedit })
$tab2.Controls.Add($btnRegedit)

$btnEventViewer = New-Object System.Windows.Forms.Button
$btnEventViewer.Location = New-Object System.Drawing.Point(190, 95)
$btnEventViewer.Size = New-Object System.Drawing.Size(170, 35)
$btnEventViewer.Text = '📋 Logboeken'
$btnEventViewer.Add_Click({ Start-Process eventvwr.msc })
$tab2.Controls.Add($btnEventViewer)

$btnPing = New-Object System.Windows.Forms.Button
$btnPing.Location = New-Object System.Drawing.Point(370, 95)
$btnPing.Size = New-Object System.Drawing.Size(170, 35)
$btnPing.Text = '🌐 Ping Google'
$btnPing.Add_Click({
    $toolsOutputBox.Text = "Bezig met pingen..."
    $result = Test-Connection google.com -Count 4 | Out-String
    $toolsOutputBox.Text = $result
})
$tab2.Controls.Add($btnPing)

$btnIPConfig = New-Object System.Windows.Forms.Button
$btnIPConfig.Location = New-Object System.Drawing.Point(10, 140)
$btnIPConfig.Size = New-Object System.Drawing.Size(170, 35)
$btnIPConfig.Text = '🔍 IP Configuratie'
$btnIPConfig.Add_Click({
    $toolsOutputBox.Text = "Bezig met laden..."
    $result = ipconfig /all | Out-String
    $toolsOutputBox.Text = $result
})
$tab2.Controls.Add($btnIPConfig)

$btnFlushDNS = New-Object System.Windows.Forms.Button
$btnFlushDNS.Location = New-Object System.Drawing.Point(190, 140)
$btnFlushDNS.Size = New-Object System.Drawing.Size(170, 35)
$btnFlushDNS.Text = '🔄 DNS Cache Legen'
$btnFlushDNS.Add_Click({
    ipconfig /flushdns | Out-Null
    $toolsOutputBox.Text = "✅ DNS cache succesvol geleegd!"
})
$tab2.Controls.Add($btnFlushDNS)

# Tab 3: Over
$tab3 = New-Object System.Windows.Forms.TabPage
$tab3.Text = 'ℹ️ Over'
$tabControl.Controls.Add($tab3)

$aboutText = New-Object System.Windows.Forms.TextBox
$aboutText.Location = New-Object System.Drawing.Point(10, 10)
$aboutText.Size = New-Object System.Drawing.Size(545, 290)
$aboutText.Multiline = $true
$aboutText.ScrollBars = 'Vertical'
$aboutText.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$aboutText.ReadOnly = $true
$aboutText.Text = @"
╔══════════════════════════════════════════════════════╗
║       PowerShell GUI Tool v1.0                      ║
╚══════════════════════════════════════════════════════╝

📦 One-Line Installer Tool
   Start deze tool met één regel PowerShell!

🚀 Gebruik:
   irm https://raw.githubusercontent.com/pieterpostNL/PowerShell-GUI-Tool/main/tool.ps1 | iex

✨ Functies:
   • Systeem informatie
   • Schijf en netwerk analyse
   • Handige Windows tools
   • Modern GUI interface
   • Plug & Play installatie

🔧 Vereisten:
   • PowerShell 5.1 of hoger
   • Windows OS
   • Minimale rechten vereist

💡 Tips:
   • Druk op de knoppen om functies uit te proberen
   • Gebruik de tabs om tussen secties te schakelen
   • Alle info wordt real-time opgehaald

📝 Repository:
   github.com/pieterpostNL/PowerShell-GUI-Tool

⚖️ Licentie: MIT
📅 Versie: 1.0
👨‍💻 Made with PowerShell
"@
$tab3.Controls.Add($aboutText)

# Footer buttons
$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Location = New-Object System.Drawing.Point(450, 460)
$btnClose.Size = New-Object System.Drawing.Size(120, 35)
$btnClose.Text = '❌ Sluiten'
$btnClose.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35)
$btnClose.ForeColor = [System.Drawing.Color]::White
$btnClose.FlatStyle = 'Flat'
$btnClose.Add_Click({ $form.Close() })
$form.Controls.Add($btnClose)

# Versie label
$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Location = New-Object System.Drawing.Point(20, 470)
$versionLabel.Size = New-Object System.Drawing.Size(200, 20)
$versionLabel.Text = 'v1.0 | github.com/pieterpostNL'
$versionLabel.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($versionLabel)

# Laad systeem info bij opstarten
$systemInfoBox.Text = Get-SystemInfo

# Toon het formulier
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()