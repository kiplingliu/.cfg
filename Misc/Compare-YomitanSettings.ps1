[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OldSettings,

    [Parameter(Mandatory)]
    [string]$NewSettings
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$removedProperties = @(
    ".date"
    ".manifest.version"
    ".options.profiles[].options.dictionaries"
    ".options.profiles[].options.general.mainDictionary"
    ".permissions.permissions"
    ".userAgent"
)
$filter = "del($($removedProperties -join ","))"

$filteredOld = $null
$filteredNew = $null

try {
    $filteredOld = New-TemporaryFile
    $filteredNew = New-TemporaryFile

    jq $filter $OldSettings > $filteredOld
    jq $filter $NewSettings > $filteredNew

    & {
        $PSNativeCommandUseErrorActionPreference = $false

        jd $filteredOld.FullName $filteredNew.FullName
    }
}
finally {
    foreach ($file in @($filteredOld, $filteredNew)) {
        if ($null -ne $file) {
            Remove-Item $file -ErrorAction SilentlyContinue
        }
    }
}
