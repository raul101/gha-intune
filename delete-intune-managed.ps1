#mandatory graph token param
[CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GraphToken
    )
    
#Variables (will be pa
$DeviceName = "UK-AWS-CFFE4E12"

#request headers        
$headers = @{
  "Content-Type" = "application/json"
   Authorization = "Bearer {0}" -f $GraphToken}
#url
$apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$filter=eq(deviceName, $DeviceName)&Select=Id"

#get managed device id from device name
$ManagedDevice = Invoke-RestMethod -Uri $apiUrl -Method GET -Headers $headers
$ManagedId = $ManagedDevice.value.Id

#Delete device
$apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$ManagedId"
Invoke-RestMethod -Uri $apiUrl -Method DELETE -Headers $headers
