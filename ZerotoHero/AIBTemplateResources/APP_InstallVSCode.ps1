<#
.SYNOPSIS
    This script installs the latest version of Visual Studio Code using the Evergreen PowerShell module.

.DESCRIPTION
    The script will first ensure that the PowerShell Gallery is trusted, and then it will install or update the Evergreen module. 
    It will then use Evergreen to download the latest stable version of Visual Studio Code and install it.

    This script was written by Alex Durrant. You can find more of his work at https://letsconfigmgr.com
    The Evergreen module was developed by Aaron Parker. More details can be found at https://stealthpuppy.com/evergreen/

.EXAMPLE
    .\AVD_APP_InstallVSCode.ps1
#>

# Trust PowerShell Gallery
If ((Get-PSRepository | Where-Object { $_.Name -eq "PSGallery" -and $_.InstallationPolicy -ne "Trusted" })) {
    # Install NuGet package provider, which is required to trust the PowerShell Gallery
    Install-PackageProvider -Name "NuGet" -MinimumVersion 2.8.5.208 -Force
    # Trust the PowerShell Gallery
    Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"
}

# Install or update Evergreen module
$InstalledEvergreen = Get-Module -Name "Evergreen" -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
$PublishedEvergreen = Find-Module -Name "Evergreen"

If ($null -eq $InstalledEvergreen) {
    # Evergreen module is not installed, so install it
    Install-Module -Name "Evergreen"
}
ElseIf ($PublishedEvergreen.Version -gt $InstalledEvergreen.Version) {
    # A newer version of the Evergreen module is available, so update it
    Update-Module -Name "Evergreen"
}

# Download the latest stable version of Visual Studio Code using the Evergreen module
$VSCodeInfo = Get-EvergreenApp -Name MicrosoftVisualStudioCode | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Platform -eq "win32-x64" }
$VSCodeInstallerPath = $VSCodeInfo | Save-EvergreenApp -Path "C:\Temp\VSCode"

# Install Visual Studio Code
Start-Process -FilePath $VSCodeInstallerPath -ArgumentList "/VERYSILENT /NORESTART /MERGETASKS=!runcode" -Wait -Verbose

# Cleanup temporary directory
Remove-Item -Path $VSCodeInstallerPath -Force -Recurse -ErrorAction SilentlyContinue
