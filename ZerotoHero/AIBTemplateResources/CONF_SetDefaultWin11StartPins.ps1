# Reference: Alex Durrant's blog (https://letsconfigmgr.com)
# Script to set a default Start menu PIN layout for Windows 11 devices

# Define URLs, file paths, and locations
$StartBinURL = 'https://your-storage-account-url/start2.bin'
$DownloadLocation = 'C:\AIBTemp\start2.bin'
$DestinationFolder = Join-Path -Path $env:SystemDrive -ChildPath 'Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState'
$DestinationFile = Join-Path -Path $DestinationFolder -ChildPath 'start2.bin'

# Download the start2.bin file
Invoke-WebRequest -Uri $StartBinURL -OutFile $DownloadLocation

# Create the destination folder if it doesn't exist
if (-not (Test-Path -Path $DestinationFolder)) {
    New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
}

# Copy the downloaded file to the destination
Copy-Item -Path $DownloadLocation -Destination $DestinationFile -Force

# Cleanup the downloaded file
if (Test-Path -Path $DownloadLocation) {
    Remove-Item -Path $DownloadLocation -Force
}
