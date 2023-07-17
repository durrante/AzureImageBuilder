<#
.SYNOPSIS
This script, authored by Alex Durrant, removes the Microsoft Teams "Chat" icon from the Windows taskbar by modifying a specific registry setting.

.DESCRIPTION
The script first defines the registry path where the setting for the Microsoft Teams "Chat" icon is located. 
It then checks if this registry path exists. If it doesn't, the script creates the registry path. 
Finally, the script sets the value of the "ChatIcon" property to "3", which effectively removes the icon from the taskbar.

For more resources and scripts, visit Alex Durrant's blog: https://letsconfigmgr.com
#>

# Define the registry path
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"

# Check if the registry path exists, if not, create it
if (!(Test-Path $registryPath)) { 
    # Create the registry path
    New-Item -Path $registryPath -Force
}

# Set the property value to "3", which removes the Teams "Chat" icon from the taskbar
Set-ItemProperty -Path $registryPath -Name "ChatIcon" -Value 3
