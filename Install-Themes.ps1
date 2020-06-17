$ErrorActionPreference = "Inquire"
$InformationPreference = "Continue"

# Ensure Windows compatibility
#   This should always throw on non-Windows device or Windows 7 or below.
if (!(Get-Command Get-AppxPackage)){
    throw "This script can only be run on an Appx-compatible device."
}

# Get WindowsTerminal package name
$terminalAppx = Get-AppxPackage -Name Microsoft.WindowsTerminal
if ($null -eq $terminalAppx) {
    throw "Windows Terminal is not installed."
}

# Get LocalState config directory
$terminalConfigPath = [System.IO.Path]::Combine($env:LOCALAPPDATA, "packages", $terminalAppx.PackageFamilyName, "LocalState")
if (!(Test-Path $terminalConfigPath)) {
    throw "Windows Terminal configuration path not found."
}

$settingsJson = [System.IO.Path]::Combine($PSScriptRoot, "src", "settings.json")
$settingsPath = [System.IO.Path]::GetDirectoryName($settingsJson)
if (!(Test-Path $settingsJson)){
    throw "Installation files not found."
}

$targetConfig = [System.IO.Path]::Combine($terminalConfigPath, "settings.json")
if (Test-Path $targetConfig){
    Write-Information "Found settings.json. Renaming to settings.json.bak..."
    Rename-Item -LiteralPath $targetConfig "settings.json.bak"
}
$files = Get-ChildItem -LiteralPath $settingsPath
$files | Copy-Item -Destination $terminalConfigPath -Force

Write-Information "Finished installing Windows Terminal settings. Enjoy!"
Read-Host -Prompt "Press any key to exit."