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
        
$headers = @{
  "Content-Type" = "application/json"
   Authorization = "Bearer {0}" -f $GraphToken}
$apiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?$filter=contains(serialNumber, $SerialNumber)and contains(manufacturer, $Manufacturer)"
$method = "GET"
$AutopilotDevices = Invoke-RestMethod -Uri $apiUrl -Method $method -Headers $headers
ForEach ($AutopilotDevice in $AutopilotDevices)
  {$Serial = $AutopilotDevice.value.serialNumber
    If ($Serial.StartsWith("Parallels"))# -and $Serial.Endswith("CF FE 4E 12"))
         {$ID = $AutopilotDevice.value.Id
         Write-Host $ID`n$Serial
         #Run delete
         }
  }
