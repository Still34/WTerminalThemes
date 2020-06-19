$ErrorActionPreference = "Inquire"
$InformationPreference = "Continue"

function Install-PackageViaScoop($ScoopExe, $Package) {
    Start-Process $ScoopExe -ArgumentList ("install", $Package) -Wait -NoNewWindow
}
function Get-Scoop {
    $scoop = (Get-Command scoop.cmd -ErrorAction SilentlyContinue).Source
    if ($null -eq $scoop) {
        Write-Warning "Scoop is not installed. Installing scoop..."
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        $scoop = (Get-Command scoop.cmd).Source
        if (($LASTEXITCODE -gt 0) -or ($null -eq $scoop)) {
            throw "An error occurred while installing scoop."
        }
    }
    return $scoop
}
function Install-Dependencies {
    $dependencies = "php", "node", "python3", "gsudo"
    foreach ($dependency in $dependencies) {
        if (!(Get-Command $dependency -ErrorAction SilentlyContinue)) {
            $choices = '&Yes', '&No'
            $installScoop = $Host.UI.PromptForChoice("Dependency ($dependency) is not detected.", "Use scoop to resolve the dependency?", $choices, 0)
            if ($installScoop -eq 0) {
                $scoop = Get-Scoop
                Install-PackageViaScoop -ScoopExe $scoop -Package $dependency
            }
            else {
                Write-Warning "Dependency ($dependency) is not installed. One or more of the installed terminals may not work as expected." -WarningAction "Continue"
            }
        }
    }
}
function Install-Config {
    # Ensure Windows compatibility
    #   This should always throw on non-Windows device or Windows 7 or below.
    if (!(Get-Command Get-AppxPackage)) {
        throw "This script can only be run on an Appx-compatible device."
    }

    # Get WindowsTerminal package name
    $terminalAppxs = Get-AppxPackage -Name Microsoft.WindowsTerminal*
    if ($null -eq $terminalAppx) {
        throw "Windows Terminal is not installed."
    }
    foreach ($terminalAppx in $terminalAppxs) {
        # Get LocalState config directory
        $terminalConfigPath = [System.IO.Path]::Combine($env:LOCALAPPDATA, "packages", $terminalAppx.PackageFamilyName, "LocalState")
        if (!(Test-Path $terminalConfigPath)) {
            throw "Windows Terminal configuration path not found."
        }

        $settingsJson = [System.IO.Path]::Combine($PSScriptRoot, "src", "settings.json")
        $settingsPath = [System.IO.Path]::GetDirectoryName($settingsJson)
        if (!(Test-Path $settingsJson)) {
            throw "Installation files not found."
        }

        $targetConfig = [System.IO.Path]::Combine($terminalConfigPath, "settings.json")
        $configBackupPath = $targetConfig + [DateTime]::Now.ToString('-yyyy-MM-dd_hh.mm.ss') + ".bak"
        if (Test-Path $targetConfig) {
            $targetConfigHash = Get-FileHash -Algorithm SHA256 -LiteralPath $targetConfig
            $srcConfigHash = Get-FileHash -Algorithm SHA256 -LiteralPath $settingsJson
            if ($targetConfigHash.Hash -ne $srcConfigHash.Hash) {
                Write-Warning "Found previous config, backing up to $configBackupPath..." -WarningAction Continue
                if (Test-Path $configBackupPath) {
                    Remove-Item -LiteralPath $configBackupPath
                }
                Rename-Item -LiteralPath $targetConfig $configBackupPath
            }
        }
        $files = Get-ChildItem -LiteralPath $settingsPath
        $files | Copy-Item -Destination $terminalConfigPath -Force
    }

    Write-Host "Finished installing Windows Terminal settings. Enjoy!" -BackgroundColor DarkGreen
}

Install-Dependencies
Install-Config