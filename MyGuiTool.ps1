Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Maak het hoofdvenster
$form = New-Object System.Windows.Forms.Form
$form.Text = 'PowerShell GUI Tool'
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Titel label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(460, 30)
$titleLabel.Text = 'Welkom bij je PowerShell Tool'
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($titleLabel)

# Beschrijving label
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Location = New-Object System.Drawing.Point(20, 60)
$descLabel.Size = New-Object System.Drawing.Size(460, 40)
$descLabel.Text = 'Dit is een voorbeeld GUI-tool die met één regel kan worden gestart.'
$form.Controls.Add($descLabel)

# Input groep
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Location = New-Object System.Drawing.Point(20, 120)
$inputLabel.Size = New-Object System.Drawing.Size(460, 20)
$inputLabel.Text = 'Voer een waarde in:'
$form.Controls.Add($inputLabel)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20, 145)
$textBox.Size = New-Object System.Drawing.Size(460, 25)
$form.Controls.Add($textBox)

# Output textbox
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Location = New-Object System.Drawing.Point(20, 185)
$outputLabel.Size = New-Object System.Drawing.Size(460, 20)
$outputLabel.Text = 'Resultaat:'
$form.Controls.Add($outputLabel)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 210)
$outputBox.Size = New-Object System.Drawing.Size(460, 80)
$outputBox.Multiline = $true
$outputBox.ScrollBars = 'Vertical'
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

# Actie button
$actionButton = New-Object System.Windows.Forms.Button
$actionButton.Location = New-Object System.Drawing.Point(20, 310)
$actionButton.Size = New-Object System.Drawing.Size(150, 30)
$actionButton.Text = 'Uitvoeren'
$actionButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$actionButton.ForeColor = [System.Drawing.Color]::White
$actionButton.FlatStyle = 'Flat'
$actionButton.Add_Click({
    if ($textBox.Text -ne '') {
        $result = "Je hebt ingevoerd: $($textBox.Text)`n"
        $result += "Tijdstip: $(Get-Date -Format 'HH:mm:ss')`n"
        $result += "Computer: $env:COMPUTERNAME"
        $outputBox.Text = $result
    } else {
        [System.Windows.Forms.MessageBox]::Show('Voer eerst een waarde in!', 'Waarschuwing', 'OK', 'Warning')
    }
})
$form.Controls.Add($actionButton)

# Info button
$infoButton = New-Object System.Windows.Forms.Button
$infoButton.Location = New-Object System.Drawing.Point(180, 310)
$infoButton.Size = New-Object System.Drawing.Size(150, 30)
$infoButton.Text = 'Systeem Info'
$infoButton.Add_Click({
    $info = "OS: $((Get-CimInstance Win32_OperatingSystem).Caption)`n"
    $info += "Versie: $((Get-CimInstance Win32_OperatingSystem).Version)`n"
    $info += "Gebruiker: $env:USERNAME`n"
    $info += "PowerShell: $($PSVersionTable.PSVersion)"
    $outputBox.Text = $info
})
$form.Controls.Add($infoButton)

# Sluiten button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Point(340, 310)
$closeButton.Size = New-Object System.Drawing.Size(140, 30)
$closeButton.Text = 'Sluiten'
$closeButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($closeButton)

# Toon het formulier
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()