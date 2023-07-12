<#
.SYNOPSIS
    This script installs the latest version of Mozilla Firefox using the Evergreen PowerShell module.

.DESCRIPTION
    The script will first ensure that the PowerShell Gallery is trusted, and then it will install or update the Evergreen module. 
    It will then use Evergreen to download the latest version of Mozilla Firefox and install it.

    This script was written by Alex Durrant. You can find more of his work at https://letsconfigmgr.com
    The Evergreen module was developed by Aaron Parker. More details can be found at https://stealthpuppy.com/evergreen/

.EXAMPLE
    .\AVD_APP_InstallFirefox.ps1
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

# Download the latest version of Mozilla Firefox using the Evergreen module
$FirefoxInfo = Get-EvergreenApp -Name MozillaFirefox | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "LATEST_FIREFOX_VERSION" -and $_.Type -eq "msi" }
$FirefoxInstallerPath = $FirefoxInfo | Save-EvergreenApp -Path "C:\AIBTemp\Firefox"

# Install Mozilla Firefox
Start-Process -FilePath msiexec.exe -ArgumentList "/I `"$FirefoxInstallerPath`" /quiet" -Wait -Verbose

# Cleanup temporary directory
Remove-Item -Path $FirefoxInstallerPath -Force -Recurse -ErrorAction SilentlyContinue
