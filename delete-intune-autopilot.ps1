<#
.SYNOPSIS
    Deletes a Windows Autopilot device identity from Intune.

.DESCRIPTION
    This script connects to Microsoft Graph to find and delete a specific
    Windows Autopilot device identity based on a partial serial number match
    and manufacturer. It then performs an explicit check to ensure the full
    serial number starts with 'ec2' and ends with the provided partial
    serial number. It includes robust validation and error handling for safe operation.

.PARAMETER GraphToken
    The access token for authenticating with Microsoft Graph. This token must
    have 'DeviceManagementServiceConfig.ReadWrite.All' application permissions.

.PARAMETER DeviceName
    The device name from the aws workspaces console. Only the last 8 digits are used. For example UK-AWS-12345678 is parsed to '12345678' The device name must start with 'UK-AWS-'.

.PARAMETER Manufacturer
    The manufacturer of the Autopilot device (e.g., 'Amazon EC2'). This is used
    for filtering the initial graph query.
    
.NOTES
    Author: Craig Murphy
    Version: 1.0
    Date: 2025-07-15
    Prerequisites:
        - Azure AD App Registration with 'DeviceManagementServiceConfig.ReadWrite.All'
          application permission.
        - PowerShell 5.1 or later.
        - GraphToken must be obtained using client credentials flow.
    Usage:
        .\Delete-AutopilotDevice.ps1 -GraphToken "your_token" -DeviceName "UK-AWS-12345678" -Manufacturer "Amazon EC2"

.EXAMPLE
    .\Delete-AutopilotDevice.ps1 -GraphToken "eyJ..." -DeviceName "UK-AWS-12345678" -Manufacturer "Amazon EC2"
#>

#mandatory graph token param
[CmdletBinding()]
param(
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$GraphToken,
    
    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("UK-AWS-*")]
    [string]$DeviceName,

    [parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Manufacturer
    )


#get serial number from device name
$SerialNumber = $DeviceName.TrimStart("UK-AWS-")

#request headers
$headers = @{
  "Content-Type" = "application/json"
   Authorization = "Bearer {0}" -f $GraphToken}
#url
$apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber, '$SerialNumber') and contains(manufacturer, '$Manufacturer')"

Write-Host "Searching for Autopilot device with Serial Number containing '$SerialNumber' and Manufacturer containing '$Manufacturer'..."

#get autopilot devices
$AutopilotDevices = $null
try { $AutopilotDevices = Invoke-RestMethod -Uri $apiUrl -Method GET -Headers $headers -ErrorAction Stop }
catch {
    Write-Error "Failed to query Autopilot device information from Microsoft Graph. Error: $($_.Exception.Message)"
    exit 1
}

#check api call
if (-not $AutopilotDevices -or -not $AutopilotDevices.value -or $AutopilotDevices.value.Count -eq 0) {
    Write-Warning "No Autopilot device found matching Partial Serial Number: '$SerialNumber' and Manufacturer: '$Manufacturer' during initial Graph query. Nothing to delete."
    exit 0 # Exit successfully, as there's nothing to do
}

#init variable
$ID = $null

#for each loop to ensure device is correct, unable to use equals in device identities filter
ForEach ($AutopilotDevice in $AutopilotDevices.value)
  {If ($AutopilotDevice.serialNumber -like "1400*" -and $AutopilotDevice.serialNumber -like "*$SerialNumber") #if matches
         {$ID = $AutopilotDevice.Id #set Id
          Write-Host "Found exact match for '$DeviceName'. Device ID is '$ID'"
          break}
         }

# check if found
if (-not $ID) {
    Write-Warning "No *exact* Autopilot device found matching the required serial number pattern (Starts with '$Manufacturer', Ends with '$SerialNumber') after further filtering. Nothing to delete."
    exit 0 # Exit successfully if no exact match found
}
        
#delete device
$apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/$ID"

Write-Host "Attempting to delete Autopilot device with ID: '$ID'..."

#try {Invoke-RestMethod -Uri $apiUrl -Method DELETE -Headers $headers -ErrorAction Stop
#     exit 0}
#catch {Write-Error "Failed to delete Autopilot device '$DeviceName'. Error: $($_.Exception.Message)"
#       exit 1}
         
