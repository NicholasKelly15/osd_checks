$installedAppsRegistryKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\';
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'; 
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\'; 
    'HKCU:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
)

function Get-RequiredApps {
    param (
        [String[]]$paths
    )

    $required_apps = @()
    foreach ($path in $paths) {
        Import-Csv $path | ForEach-Object -Process {$required_apps += $_}
    }

    return $required_apps
}

function Get-AppsFromRegistryKey {

    param (
        [String]$registryKey
    )
    
    $apps = New-Object Collections.Generic.List[String]
    foreach ($key in Get-ChildItem -Path $registryKey) {
        $displayName = (Get-ItemProperty -Path $key.PSPath).DisplayName
        if ($displayName) {
            $apps.Add($displayName)
        }
    }
    
    return $apps
}

function Get-RegistryApps {
    $apps = @()
    foreach ($registryKey in $installedAppsRegistryKeys) {
        $ErrorActionPreference = 'stop'
        try {
            Get-AppsFromRegistryKey $registryKey | ForEach-Object -Process {$apps += $_}
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            # The registry path does not exist, ignore this
        }
        $ErrorActionPreference = 'continue'
    }

    return $apps
}

function Get-InstalledApps {
    return Get-Package
}

$requiredApps = Get-RequiredApps Hub_Only_Apps.csv, WFDC_Base_Apps.csv
$registryApps = Get-RegistryApps

