<#
.SYNOPSIS
    Deletes an Intune managed device by its device name and user principal name.

.DESCRIPTION
    This script connects to Microsoft Graph using client credentials to find and
    delete a specific Intune managed device. It performs robust validation
    for all input parameters and includes comprehensive error handling.

.PARAMETER GraphToken
    The access token for authenticating with Microsoft Graph. This token must
    have 'DeviceManagementManagedDevices.ReadWrite.All' application permissions.

.PARAMETER DeviceName
    The exact name of the Intune device to be deleted (e.g., 'UK-AWS-MyPC').
    Must start with 'UK-AWS-'.

.PARAMETER UPN
    The User Principal Name (UPN) of the primary user associated with the device.

.NOTES
    Author: Craig Murphy
    Version: 1.0
    Date: 2025-07-15
    Prerequisites:
        - Azure AD App Registration with 'DeviceManagementManagedDevices.ReadWrite.All' application permission.
        - PowerShell 5.1 or later.
        - Azure AD app credentials (Tenant ID, Client ID, Client Secret) to obtain GraphToken.
    Usage:
        .\Delete-IntuneDevice.ps1 -GraphToken "your_token" -DeviceName "UK-AWS-TESTPC" -UPN "user@example.com"

.EXAMPLE
    .\Delete-IntuneDevice.ps1 -GraphToken "xyz..." -DeviceName "UK-AWS-DESKTOP-01" -UPN "jane.doe@contoso.com"

.EXAMPLE
    # Example for GitHub Actions workflow usage
    # (assuming token generation happens earlier or is passed as a secret)
    # run: |
    #   .\Delete-IntuneDevice.ps1 `
    #     -GraphToken "${{ secrets.GRAPH_TOKEN }}" `
    #     -DeviceName "${{ inputs.deviceName }}" `
    #     -UPN "${{ inputs.upn }}"
#>

#mandatory params
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
    [string]$UPN
)

#request headers        
$headers = @{
    "Content-Type" = "application/json"
    Authorization  = "Bearer {0}" -f $GraphToken
}
#url
$apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=(deviceName eq '$DeviceName' and userPrincipalName eq '$UPN')&`$Select=Id,deviceName,SerialNumber"

#get managed device from device name and upn

Write-Host "Searching for intune device with device name '$DeviceName' and UPN '$UPN'..."

$ManagedDevice = $null
try { $ManagedDevice = Invoke-RestMethod -Uri $apiUrl -Method GET -Headers $headers -ErrorAction Stop }
catch {
    Write-Error "Failed to query device information from Microsoft Graph. Error: $($_.Exception.Message)"
    exit 1
}

#check result is not empty
if (-not $ManagedDevice -or -not $ManagedDevice.value -or $ManagedDevice.value.Count -eq 0) {
    Write-Warning "No device found matching Name: '$DeviceName' and UPN: '$UPN'. Nothing to delete."
    exit 0
}

#handle multiple devices
    if ($ManagedDevice.value.Count -gt 1) {
        Write-Error "Multiple devices found with the name '$DeviceName' and UPN '$UPN'."
        exit 1
    }

#confirm device and get managed id
If ($ManagedDevice.value[0].deviceName -eq $DeviceName)
        {$ManagedId = $ManagedDevice.value[0].Id}
Else {Write-Error "Incorrect device name for '$DeviceName' or device not found"
      exit 1}

Write-Host "Attempting to delete intune device with ID: '$ManagedID'..."

#delete device
$apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$ManagedId"
try {
    Invoke-RestMethod -Uri $apiUrl -Method DELETE -Headers $headers -ErrorAction Stop
    exit 0
}
catch {
    Write-Error "Failed to delete Intune device '$DeviceName' (ID: $ManagedId). Error: $($_.Exception.Message)"
    exit 1
}
