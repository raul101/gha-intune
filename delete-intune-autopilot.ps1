#mandatory graph token param
[CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GraphToken
    )


#Variables
$SerialNumber = "CF FE 4E 12"
$Manufacturer = "Parallels"

#request headers
$headers = @{
  "Content-Type" = "application/json"
   Authorization = "Bearer {0}" -f $GraphToken}
#url
$apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?$filter=contains(serialNumber, $SerialNumber)and contains(manufacturer, $Manufacturer)"

#get autopilot devices
$AutopilotDevices = Invoke-RestMethod -Uri $apiUrl -Method GET -Headers $headers

#for each look to ensure device is correct, unable to use equals in device identities filter
ForEach ($AutopilotDevice in $AutopilotDevices)
  {$Serial = $AutopilotDevice.value.serialNumber #get serial
    If ($Serial.StartsWith("Parallels"))# -and $Serial.Endswith("CF FE 4E 12")) #if matches
         {$ID = $AutopilotDevice.value.Id #set Id
         #delete device
         $apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/$ID"
         Invoke-RestMethod -Uri $apiUrl -Method DELETE -Headers $headers
         }
    Else
      {}
  }
