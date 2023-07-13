Import-Module -Name .\drivers.ps1

$OutputRegisterKey = 'HKLM:\SOFTWARE\Wells Fargo\OSD\Testing'
$OutputFolder = 'C:\Users\nvk58\Desktop\TestingLogs'

Start-Transcript -OutputDirectory $OutputFolder

# Getting devices and driver data
$DevicesAndDrivers = Get-PnPDevicesAndDrivers
$DevicesWithoutDrivers = $DevicesAndDrivers | Where-Object ConfigManagerErrorCode -NE 0
$DriversSummary = 'Pass'
if ($DevicesWithoutDrivers.length -gt 0) {
    $DriversSummary = 'Fail: '
    foreach ($driver in $DevicesWithoutDrivers) {
        $DriversSummary += $driver.Name + ', '
    }
    $DriversSummary = $DriversSummary.Substring(0, $DriversSummary.length - 2)
}

# Getting application data

# Domain Joined?
$Domain = (Get-WmiObject win32_computersystem).Domain
$DomainJoined = "Fail: Domain = $Domain"
if ($Domain -eq 'ent.wfb.bank.corp') {
    $DomainJoined = 'Pass'
}

# Summarizing results in the registry
$ResultsSummary = @{}
$ResultsSummary.add('ComputerName', $env:computername)
$ResultsSummary.add('InstallDate', [datetime]::now.tostring('s'))
$ResultsSummary.add('Drivers', $DriversSummary)
$ResultsSummary.add('DomainJoined', $DomainJoined)

write-host 'testing results: '
new-item -path $OutputRegisterKey -force | out-null
$ResultsSummary.keys | foreach-object {
    new-itemproperty -path $OutputRegisterKey -name $_ -value $ResultsSummary[$_]
}
New-Object PSObject -Property $ResultsSummary | Export-Csv $OutputFolder\topline.csv -NoTypeInformation
Get-ItemProperty $OutputRegisterKey

Stop-Transcript