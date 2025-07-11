[CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GraphToken
    )
    
#Variables
$DeviceName = "UK-AWS-CFFE4E12"
        
$headers = @{
  "Content-Type" = "application/json"
   Authorization = "Bearer {0}" -f $GraphToken}
$apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$filter=eq(deviceName, $DeviceName)&Select=Id"
$method = "GET"
$ManagedDevice = Invoke-RestMethod -Uri $apiUrl -Method $method -Headers $headers
$ManagedId = $ManagedDevice.value.Id
Write-Host $ManagedId

#Delete
#
