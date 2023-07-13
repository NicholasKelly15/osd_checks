function Get-PnPDevicesAndDrivers {

    $devices = Get-WmiObject Win32_PnPEntity
    $drivers = Get-WmiObject Win32_PnPSignedDriver

    $deviceAndDriverDetails = $devices | Select-Object Name, DeviceID, ConfigManagerErrorCode, 
    @{
        Name = "DriverVersion"; 
        Expression = {(Get-DeviceDriver -deviceID $_.DeviceID -drivers $drivers).DriverVersion}
    }, 
    @{
        Name = "IsSigned"; 
        Expression = {(Get-DeviceDriver -deviceID $_.DeviceID -drivers $drivers).IsSigned}
    }, 
    @{
        Name = "Signer"; 
        Expression = {(Get-DeviceDriver -deviceID $_.DeviceID -drivers $drivers).Signer}
    }
    
    return $deviceAndDriverDetails

}

function Get-DeviceDriver {
    param (
        [String]$deviceID, 
        [Object[]]$drivers
    )

    foreach ($driver in $drivers) {
        if ($driver.DeviceID -eq $deviceID) {
            return $driver
        }
    }
    return $NULL
}


