# This script checks if Google Chrome is installed by looking for its registry key

$DisplayName = "Google Chrome"
$check = $false

Get-ChildItem -Path HKLM:\software\microsoft\windows\currentversion\uninstall -Recurse -ErrorAction SilentlyContinue | % {
    if ((Get-ItemProperty -Path $_.pspath).DisplayName -eq $DisplayName) {
        $check = $true
    }
}

Get-ChildItem -Path HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall -Recurse -ErrorAction SilentlyContinue | % {
    if ((Get-ItemProperty -Path $_.pspath).DisplayName -eq $DisplayName) {
        $check = $true
    }
}

if ($check) {
    Write-Output "Google Chrome is installed."
    exit 0
} else {
    Write-Output "Google Chrome is not installed."
    exit 1
}
