Import-Module -Name $PSScriptRoot\drivers.ps1
Import-Module -Name $PSScriptRoot\applications.ps1

$OutputRegisterKey = 'HKLM:\SOFTWARE\Wells Fargo\OSD\Testing'
$OutputFolder = "$PSScriptRoot\Logs"

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

Write-Host 'testing results: '
$ErrorActionPreference = 'stop'
try {
    new-item -path $OutputRegisterKey -force | Out-Null
    $ResultsSummary.keys | foreach-object {
        new-itemproperty -path $OutputRegisterKey -name $_ -value $ResultsSummary[$_] | Out-Null
    }
    # Get-ItemProperty $OutputRegisterKey
}
catch [System.Security.SecurityException] {
    Write-Host 'Unable to write top line results to registry' -ForegroundColor Red
}
$ErrorActionPreference = 'continue'

$ResultsObject = New-Object PSObject -Property $ResultsSummary
$ResultsObject | Export-Csv $OutputFolder\topline.csv -NoTypeInformation
Write-Host $ResultsObject


Stop-Transcript