Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName Microsoft.VisualBasic

$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$DriversBase = Join-Path $Base "Drivers"
$Logs = Join-Path $Base "Logs"
$Log = Join-Path $Logs "ps.log"

New-Item -ItemType Directory -Force -Path $DriversBase,$Logs | Out-Null

function Log($m) {
    Add-Content $Log "[{0}] {1}" -f (Get-Date), $m
}

$TrustedRepos = @(
    @{
        Name = "Z790_GamingPlus_WiFi"
        Url  = "https://github.com/eltonaguiar/Drivers_Z790GamingPlusWifi/archive/refs/heads/main.zip"
    }
)

function Test-Internet {
    try {
        Invoke-WebRequest https://www.microsoft.com -UseBasicParsing -TimeoutSec 5 | Out-Null
        return $true
    } catch { return $false }
}

function Init-Network {
    Start-Process wpeinit -Wait
}

function Get-WindowsInstalls {
    Get-PSDrive -PSProvider FileSystem |
        Where-Object { Test-Path "$($_.Root)\Windows\System32\Config\SYSTEM" }
}

function Select-WindowsInstall {
    $Installs = Get-WindowsInstalls
    if ($Installs.Count -eq 1) { return $Installs[0].Root }

    $msg = "Select Windows installation:`n"
    for ($i=0; $i -lt $Installs.Count; $i++) {
        $msg += "$($i+1)) $($Installs[$i].Root)`n"
    }

    $choice = [Microsoft.VisualBasic.Interaction]::InputBox(
        $msg, "Windows Selection"
    )

    return $Installs[$choice-1].Root
}

function Download-Repo($Repo) {
    $Zip  = Join-Path $DriversBase "$($Repo.Name).zip"
    $Dest = Join-Path $DriversBase $Repo.Name

    if (Test-Path $Dest) { return $Dest }

    Log "Downloading driver repo: $($Repo.Name)"
    Invoke-WebRequest $Repo.Url -OutFile $Zip -UseBasicParsing
    Expand-Archive $Zip -DestinationPath $DriversBase -Force
    Remove-Item $Zip -Force

    return (Get-ChildItem $DriversBase | Where-Object Name -Match "Drivers_").FullName
}

function Inject-Drivers($Win,$Path) {
    Log "Injecting drivers from $Path into $Win"
    dism /Image:$Win /Add-Driver /Driver:$Path /Recurse /ForceUnsigned
}

$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
 Title="Miracle Boot (CHATGPT edition)"
 Width="480" Height="320" WindowStartupLocation="CenterScreen">
 <StackPanel Margin="20">
   <Button Name="BtnNet" Height="40" Margin="0,0,0,10">
     Initialize Internet
   </Button>
   <Button Name="BtnDrivers" Height="40">
     Install Trusted Driver Pack (Z790)
   </Button>
 </StackPanel>
</Window>
"@

$Window = [Windows.Markup.XamlReader]::Load(
    (New-Object System.Xml.XmlNodeReader ([xml]$XAML))
)

$BtnNet = $Window.FindName("BtnNet")
$BtnDrivers = $Window.FindName("BtnDrivers")

$BtnNet.Add_Click({
    if (Test-Internet) {
        [System.Windows.MessageBox]::Show("Internet already working.")
        return
    }

    Init-Network

    if (Test-Internet) {
        [System.Windows.MessageBox]::Show("Internet initialized.")
    } else {
        [System.Windows.MessageBox]::Show(
"Ethernet not working.

If Wi-Fi exists:
• Driver must be installed
• Manual SSID required

netsh wlan show interfaces
netsh wlan connect name=SSID"
        )
    }
})

$BtnDrivers.Add_Click({
    $Win = Select-WindowsInstall
    if (-not $Win) {
        [System.Windows.MessageBox]::Show("No Windows installation selected.")
        return
    }

    foreach ($Repo in $TrustedRepos) {
        $Path = Download-Repo $Repo
        Inject-Drivers $Win $Path
    }

    [System.Windows.MessageBox]::Show(
        "Driver injection complete. Reboot recommended."
    )
})

$Window.ShowDialog() | Out-Null
