# Reference: Alex Durrant's blog (https://letsconfigmgr.com)
# Script to fix first login delays due to Windows Module Installer, more information can be found here: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep-command-line-options?view=windows-11#modevm

$DeprovisioningScriptPath = 'C:\DeprovisioningScript.ps1'
$FindString = 'Sysprep.exe /oobe /generalize /quiet /quit'
$ReplacementString = 'Sysprep.exe /oobe /generalize /quit /mode:vm'

# Function to log messages
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string] $Message
    )
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
}

# Check if the script file exists
if (Test-Path -Path $DeprovisioningScriptPath) {
    # Try-catch block for error handling
    try {
        # Read the script file, replace the string, and write back to the file
        (Get-Content -Path $DeprovisioningScriptPath -Raw) -replace $FindString, $ReplacementString |
            Set-Content -Path $DeprovisioningScriptPath -Force

        Write-Log -Message 'Sysprep Mode:VM fix applied'
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Log -Message "Error updating script: $ErrorMessage"
    }
}
else {
    Write-Log -Message "The script file $DeprovisioningScriptPath does not exist"
}
