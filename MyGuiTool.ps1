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
$form.Size = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::White

# Header panel
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(700, 80)
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$form.Controls.Add($headerPanel)

# Titel label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titleLabel.Size = New-Object System.Drawing.Size(660, 30)
$titleLabel.Text = '⚡ PowerShell GUI Tool'
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$headerPanel.Controls.Add($titleLabel)

# Beschrijving label
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Location = New-Object System.Drawing.Point(20, 45)
$descLabel.Size = New-Object System.Drawing.Size(660, 25)
$descLabel.Text = 'One-line installeerbare PowerShell tool voor systeem beheer'
$descLabel.ForeColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
$headerPanel.Controls.Add($descLabel)

# Tab Control
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 90)
$tabControl.Size = New-Object System.Drawing.Size(670, 410)
$form.Controls.Add($tabControl)

# Tab 1: Systeem Info
$tab1 = New-Object System.Windows.Forms.TabPage
$tab1.Text = '🖥️ Systeem'
$tabControl.Controls.Add($tab1)

$systemInfoBox = New-Object System.Windows.Forms.TextBox
$systemInfoBox.Location = New-Object System.Drawing.Point(10, 10)
$systemInfoBox.Size = New-Object System.Drawing.Size(645, 240)
$systemInfoBox.Multiline = $true
$systemInfoBox.ScrollBars = 'Vertical'
$systemInfoBox.Font = New-Object System.Drawing.Font('Consolas', 9)
$systemInfoBox.ReadOnly = $true
$tab1.Controls.Add($systemInfoBox)

$btnSystemInfo = New-Object System.Windows.Forms.Button
$btnSystemInfo.Location = New-Object System.Drawing.Point(10, 260)
$btnSystemInfo.Size = New-Object System.Drawing.Size(200, 40)
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
$btnDiskInfo.Location = New-Object System.Drawing.Point(220, 260)
$btnDiskInfo.Size = New-Object System.Drawing.Size(200, 40)
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
$btnNetworkInfo.Location = New-Object System.Drawing.Point(430, 260)
$btnNetworkInfo.Size = New-Object System.Drawing.Size(200, 40)
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
$toolsLabel.Size = New-Object System.Drawing.Size(645, 25)
$toolsLabel.Text = 'Handige systeem tools:'
$toolsLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$tab2.Controls.Add($toolsLabel)

$toolsOutputBox = New-Object System.Windows.Forms.TextBox
$toolsOutputBox.Location = New-Object System.Drawing.Point(10, 180)
$toolsOutputBox.Size = New-Object System.Drawing.Size(645, 180)
$toolsOutputBox.Multiline = $true
$toolsOutputBox.ScrollBars = 'Vertical'
$toolsOutputBox.Font = New-Object System.Drawing.Font('Consolas', 9)
$toolsOutputBox.ReadOnly = $true
$tab2.Controls.Add($toolsOutputBox)

# Tool buttons
$btnTaskMgr = New-Object System.Windows.Forms.Button
$btnTaskMgr.Location = New-Object System.Drawing.Point(10, 50)
$btnTaskMgr.Size = New-Object System.Drawing.Size(200, 35)
$btnTaskMgr.Text = '📊 Taakbeheer'
$btnTaskMgr.Add_Click({ Start-Process taskmgr })
$tab2.Controls.Add($btnTaskMgr)

$btnDevMgr = New-Object System.Windows.Forms.Button
$btnDevMgr.Location = New-Object System.Drawing.Point(220, 50)
$btnDevMgr.Size = New-Object System.Drawing.Size(200, 35)
$btnDevMgr.Text = '🔌 Apparaatbeheer'
$btnDevMgr.Add_Click({ Start-Process devmgmt.msc })
$tab2.Controls.Add($btnDevMgr)

$btnServices = New-Object System.Windows.Forms.Button
$btnServices.Location = New-Object System.Drawing.Point(430, 50)
$btnServices.Size = New-Object System.Drawing.Size(200, 35)
$btnServices.Text = '⚙️ Services'
$btnServices.Add_Click({ Start-Process services.msc })
$tab2.Controls.Add($btnServices)

$btnRegedit = New-Object System.Windows.Forms.Button
$btnRegedit.Location = New-Object System.Drawing.Point(10, 95)
$btnRegedit.Size = New-Object System.Drawing.Size(200, 35)
$btnRegedit.Text = '📝 Register-editor'
$btnRegedit.Add_Click({ Start-Process regedit })
$tab2.Controls.Add($btnRegedit)

$btnEventViewer = New-Object System.Windows.Forms.Button
$btnEventViewer.Location = New-Object System.Drawing.Point(220, 95)
$btnEventViewer.Size = New-Object System.Drawing.Size(200, 35)
$btnEventViewer.Text = '📋 Logboeken'
$btnEventViewer.Add_Click({ Start-Process eventvwr.msc })
$tab2.Controls.Add($btnEventViewer)

$btnPing = New-Object System.Windows.Forms.Button
$btnPing.Location = New-Object System.Drawing.Point(430, 95)
$btnPing.Size = New-Object System.Drawing.Size(200, 35)
$btnPing.Text = '🌐 Ping Google'
$btnPing.Add_Click({
    $toolsOutputBox.Text = "Bezig met pingen..."
    $result = Test-Connection google.com -Count 4 | Out-String
    $toolsOutputBox.Text = $result
})
$tab2.Controls.Add($btnPing)

$btnIPConfig = New-Object System.Windows.Forms.Button
$btnIPConfig.Location = New-Object System.Drawing.Point(10, 140)
$btnIPConfig.Size = New-Object System.Drawing.Size(200, 35)
$btnIPConfig.Text = '🔍 IP Configuratie'
$btnIPConfig.Add_Click({
    $toolsOutputBox.Text = "Bezig met laden..."
    $result = ipconfig /all | Out-String
    $toolsOutputBox.Text = $result
})
$tab2.Controls.Add($btnIPConfig)

$btnFlushDNS = New-Object System.Windows.Forms.Button
$btnFlushDNS.Location = New-Object System.Drawing.Point(220, 140)
$btnFlushDNS.Size = New-Object System.Drawing.Size(200, 35)
$btnFlushDNS.Text = '🔄 DNS Cache Legen'
$btnFlushDNS.Add_Click({
    ipconfig /flushdns | Out-Null
    $toolsOutputBox.Text = "✅ DNS cache succesvol geleegd!"
})
$tab2.Controls.Add($btnFlushDNS)

# Tab 3: Windows Debloat
$tab3 = New-Object System.Windows.Forms.TabPage
$tab3.Text = '🗑️ Debloat'
$tabControl.Controls.Add($tab3)

$debloatLabel = New-Object System.Windows.Forms.Label
$debloatLabel.Location = New-Object System.Drawing.Point(10, 10)
$debloatLabel.Size = New-Object System.Drawing.Size(645, 25)
$debloatLabel.Text = 'Windows Bloatware Verwijderen:'
$debloatLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$tab3.Controls.Add($debloatLabel)

$debloatWarningLabel = New-Object System.Windows.Forms.Label
$debloatWarningLabel.Location = New-Object System.Drawing.Point(10, 40)
$debloatWarningLabel.Size = New-Object System.Drawing.Size(645, 40)
$debloatWarningLabel.Text = '⚠️ WAARSCHUWING: Deze acties kunnen niet ongedaan gemaakt worden. Maak eerst een systeemherstel punt!'
$debloatWarningLabel.ForeColor = [System.Drawing.Color]::Red
$debloatWarningLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$tab3.Controls.Add($debloatWarningLabel)

$debloatOutputBox = New-Object System.Windows.Forms.TextBox
$debloatOutputBox.Location = New-Object System.Drawing.Point(10, 230)
$debloatOutputBox.Size = New-Object System.Drawing.Size(645, 130)
$debloatOutputBox.Multiline = $true
$debloatOutputBox.ScrollBars = 'Vertical'
$debloatOutputBox.Font = New-Object System.Drawing.Font('Consolas', 8)
$debloatOutputBox.ReadOnly = $true
$tab3.Controls.Add($debloatOutputBox)

# Debloat buttons
$btnRemoveBloatware = New-Object System.Windows.Forms.Button
$btnRemoveBloatware.Location = New-Object System.Drawing.Point(10, 90)
$btnRemoveBloatware.Size = New-Object System.Drawing.Size(200, 40)
$btnRemoveBloatware.Text = '🗑️ Verwijder Bloatware Apps'
$btnRemoveBloatware.BackColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
$btnRemoveBloatware.ForeColor = [System.Drawing.Color]::White
$btnRemoveBloatware.FlatStyle = 'Flat'
$btnRemoveBloatware.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Weet je zeker dat je bloatware apps wilt verwijderen?`n`nDit verwijdert: Candy Crush, Xbox Game Bar, 3D Viewer, Mixed Reality Portal, en meer.",
        "Bevestiging",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq 'Yes') {
        $debloatOutputBox.Text = "Bezig met verwijderen van bloatware apps...`n`n"
        
        $bloatware = @(
            "Microsoft.BingWeather",
            "Microsoft.GetHelp",
            "Microsoft.Getstarted",
            "Microsoft.Microsoft3DViewer",
            "Microsoft.MicrosoftOfficeHub",
            "Microsoft.MicrosoftSolitaireCollection",
            "Microsoft.MixedReality.Portal",
            "Microsoft.People",
            "Microsoft.SkypeApp",
            "Microsoft.Wallet",
            "Microsoft.Xbox.TCUI",
            "Microsoft.XboxApp",
            "Microsoft.XboxGameOverlay",
            "Microsoft.XboxGamingOverlay",
            "Microsoft.XboxIdentityProvider",
            "Microsoft.XboxSpeechToTextOverlay",
            "Microsoft.ZuneMusic",
            "Microsoft.ZuneVideo",
            "*CandyCrush*",
            "*BubbleWitch*",
            "*Facebook*",
            "*Twitter*",
            "*LinkedIn*",
            "*Duolingo*",
            "*Spotify*"
        )
        
        foreach ($app in $bloatware) {
            try {
                $packages = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
                foreach ($package in $packages) {
                    $debloatOutputBox.AppendText("Verwijderen: $($package.Name)...`n")
                    Remove-AppxPackage -Package $package.PackageFullName -ErrorAction SilentlyContinue
                    $debloatOutputBox.AppendText("  ✅ Verwijderd`n")
                }
            }
            catch {
                $debloatOutputBox.AppendText("  ❌ Fout: $($_.Exception.Message)`n")
            }
        }
        
        $debloatOutputBox.AppendText("`n✅ Bloatware verwijdering voltooid!`n")
    }
})
$tab3.Controls.Add($btnRemoveBloatware)

$btnDisableMSStore = New-Object System.Windows.Forms.Button
$btnDisableMSStore.Location = New-Object System.Drawing.Point(220, 90)
$btnDisableMSStore.Size = New-Object System.Drawing.Size(200, 40)
$btnDisableMSStore.Text = '🚫 Uitschakelen MS Store'
$btnDisableMSStore.BackColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
$btnDisableMSStore.ForeColor = [System.Drawing.Color]::White
$btnDisableMSStore.FlatStyle = 'Flat'
$btnDisableMSStore.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Weet je zeker dat je de Microsoft Store wilt uitschakelen?",
        "Bevestiging",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq 'Yes') {
        $debloatOutputBox.Text = "Bezig met uitschakelen Microsoft Store...`n"
        try {
            Get-AppxPackage *windowsstore* | Remove-AppxPackage -ErrorAction Stop
            $debloatOutputBox.AppendText("✅ Microsoft Store succesvol uitgeschakeld!`n")
        }
        catch {
            $debloatOutputBox.AppendText("❌ Fout: $($_.Exception.Message)`n")
        }
    }
})
$tab3.Controls.Add($btnDisableMSStore)

$btnRemoveOneDrive = New-Object System.Windows.Forms.Button
$btnRemoveOneDrive.Location = New-Object System.Drawing.Point(430, 90)
$btnRemoveOneDrive.Size = New-Object System.Drawing.Size(200, 40)
$btnRemoveOneDrive.Text = '☁️ Verwijder OneDrive'
$btnRemoveOneDrive.BackColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
$btnRemoveOneDrive.ForeColor = [System.Drawing.Color]::White
$btnRemoveOneDrive.FlatStyle = 'Flat'
$btnRemoveOneDrive.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Weet je zeker dat je OneDrive wilt verwijderen?",
        "Bevestiging",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq 'Yes') {
        $debloatOutputBox.Text = "Bezig met verwijderen van OneDrive...`n"
        try {
            taskkill /f /im OneDrive.exe 2>&1 | Out-Null
            Start-Sleep -Seconds 2
            
            $oneDrivePath = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
            if (!(Test-Path $oneDrivePath)) {
                $oneDrivePath = "$env:SystemRoot\System32\OneDriveSetup.exe"
            }
            
            if (Test-Path $oneDrivePath) {
                Start-Process $oneDrivePath "/uninstall" -NoNewWindow -Wait
                $debloatOutputBox.AppendText("✅ OneDrive succesvol verwijderd!`n")
            }
            else {
                $debloatOutputBox.AppendText("❌ OneDrive installer niet gevonden`n")
            }
        }
        catch {
            $debloatOutputBox.AppendText("❌ Fout: $($_.Exception.Message)`n")
        }
    }
})
$tab3.Controls.Add($btnRemoveOneDrive)

$btnDisableTelemetry = New-Object System.Windows.Forms.Button
$btnDisableTelemetry.Location = New-Object System.Drawing.Point(10, 140)
$btnDisableTelemetry.Size = New-Object System.Drawing.Size(200, 40)
$btnDisableTelemetry.Text = '📡 Uitschakelen Telemetrie'
$btnDisableTelemetry.BackColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
$btnDisableTelemetry.ForeColor = [System.Drawing.Color]::White
$btnDisableTelemetry.FlatStyle = 'Flat'
$btnDisableTelemetry.Add_Click({
    $debloatOutputBox.Text = "Bezig met uitschakelen telemetrie...`n"
    try {
        # Stop telemetrie services
        Stop-Service DiagTrack -ErrorAction SilentlyContinue
        Stop-Service dmwappushservice -ErrorAction SilentlyContinue
        Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
        Set-Service dmwappushservice -StartupType Disabled -ErrorAction SilentlyContinue
        $debloatOutputBox.AppendText("✅ Telemetrie services uitgeschakeld!`n")
    }
    catch {
        $debloatOutputBox.AppendText("❌ Fout: $($_.Exception.Message)`n")
    }
})
$tab3.Controls.Add($btnDisableTelemetry)

$btnDisableCortana = New-Object System.Windows.Forms.Button
$btnDisableCortana.Location = New-Object System.Drawing.Point(220, 140)
$btnDisableCortana.Size = New-Object System.Drawing.Size(200, 40)
$btnDisableCortana.Text = '🎤 Uitschakelen Cortana'
$btnDisableCortana.BackColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
$btnDisableCortana.ForeColor = [System.Drawing.Color]::White
$btnDisableCortana.FlatStyle = 'Flat'
$btnDisableCortana.Add_Click({
    $debloatOutputBox.Text = "Bezig met uitschakelen Cortana...`n"
    try {
        Get-AppxPackage *Microsoft.549981C3F5F10* | Remove-AppxPackage -ErrorAction SilentlyContinue
        $debloatOutputBox.AppendText("✅ Cortana uitgeschakeld!`n")
    }
    catch {
        $debloatOutputBox.AppendText("❌ Fout: $($_.Exception.Message)`n")
    }
})
$tab3.Controls.Add($btnDisableCortana)

$btnCreateRestorePoint = New-Object System.Windows.Forms.Button
$btnCreateRestorePoint.Location = New-Object System.Drawing.Point(430, 140)
$btnCreateRestorePoint.Size = New-Object System.Drawing.Size(200, 40)
$btnCreateRestorePoint.Text = '💾 Maak Herstel Punt'
$btnCreateRestorePoint.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnCreateRestorePoint.ForeColor = [System.Drawing.Color]::White
$btnCreateRestorePoint.FlatStyle = 'Flat'
$btnCreateRestorePoint.Add_Click({
    $debloatOutputBox.Text = "Bezig met maken van systeemherstel punt...`n"
    try {
        Checkpoint-Computer -Description "PowerShell GUI Tool Backup" -RestorePointType "MODIFY_SETTINGS"
        $debloatOutputBox.AppendText("✅ Systeemherstel punt succesvol aangemaakt!`n")
    }
    catch {
        $debloatOutputBox.AppendText("❌ Fout: $($_.Exception.Message)`n")
        $debloatOutputBox.AppendText("Mogelijk zijn systeemherstel punten uitgeschakeld.`n")
    }
})
$tab3.Controls.Add($btnCreateRestorePoint)

$btnListInstalledApps = New-Object System.Windows.Forms.Button
$btnListInstalledApps.Location = New-Object System.Drawing.Point(10, 190)
$btnListInstalledApps.Size = New-Object System.Drawing.Size(200, 30)
$btnListInstalledApps.Text = '📋 Toon Alle Store Apps'
$btnListInstalledApps.Add_Click({
    $debloatOutputBox.Text = "Bezig met laden van geïnstalleerde apps...`n`n"
    $apps = Get-AppxPackage | Select-Object Name | Sort-Object Name
    foreach ($app in $apps) {
        $debloatOutputBox.AppendText("$($app.Name)`n")
    }
})
$tab3.Controls.Add($btnListInstalledApps)

# Tab 4: Over
$tab4 = New-Object System.Windows.Forms.TabPage
$tab4.Text = 'ℹ️ Over'
$tabControl.Controls.Add($tab4)

$aboutText = New-Object System.Windows.Forms.TextBox
$aboutText.Location = New-Object System.Drawing.Point(10, 10)
$aboutText.Size = New-Object System.Drawing.Size(645, 350)
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
   irm https://raw.githubusercontent.com/pieterpostNL/PowerShell-GUI-Tool/main/MyGuiTool.ps1 | iex

✨ Functies:
   • Syst