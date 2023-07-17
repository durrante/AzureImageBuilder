# Reference: Alex Durrant's blog (https://letsconfigmgr.com)
# Script to download images from public storage URLs and set desktop and lockscreen wallpapers on Windows machines

# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ("$env:PROCESSOR_ARCHITEW6432" -ne "ARM64")
{
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe")
    {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
        Exit $lastexitcode
    }
}

# Define paths, URLs, and file locations
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
$BackgroundImageURL = '<URL TO YOUR BACKGROUND IMAGE>'
$LockScreenImageURL = '<URL TO YOUR LOCKSCREEN IMAGE>'
$ImageFolder = "c:\Wallpapers"
$BackgroundImageFile = Join-Path -Path $ImageFolder -ChildPath 'desktop.jpg'
$LockScreenImageFile = Join-Path -Path $ImageFolder -ChildPath 'lockscreen.jpg'

# Check and create registry key if it does not exist
if (-not(Test-Path -Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force | Out-Null
}

# Check and create image folder if it does not exist
if (-not(Test-Path -Path $ImageFolder)) {
    New-Item -Path $ImageFolder -ItemType Directory -Force | Out-Null
}

# Download the images
Invoke-WebRequest -Uri $BackgroundImageURL -OutFile $BackgroundImageFile
Invoke-WebRequest -Uri $LockScreenImageURL -OutFile $LockScreenImageFile

# Set Lockscreen registry keys
Set-ItemProperty -Path $RegistryPath -Name "LockScreenImagePath" -Value $LockScreenImageFile -Type "String" -Force | Out-Null
Set-ItemProperty -Path $RegistryPath -Name "LockScreenImageUrl" -Value $LockScreenImageFile -Type "String" -Force | Out-Null
Set-ItemProperty -Path $RegistryPath -Name "LockScreenImageStatus" -Value 1 -Type "DWORD" -Force | Out-Null

# Set Background Wallpaper registry keys
Set-ItemProperty -Path $RegistryPath -Name "DesktopImagePath" -Value $BackgroundImageFile -Type "String" -Force | Out-Null
Set-ItemProperty -Path $RegistryPath -Name "DesktopImageUrl" -Value $BackgroundImageFile -Type "String" -Force | Out-Null
Set-ItemProperty -Path $RegistryPath -Name "DesktopImageStatus" -Value 1 -Type "DWORD" -Force | Out-Null
