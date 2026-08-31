function Invoke-Rclone {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Command,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [string[]]$RemainingArgs
    )

    $PSNativeCommandUseErrorActionPreference = $true

    $rcloneArgs = @($Command) + $RemainingArgs

    if (-not $PSCmdlet.ShouldProcess("rclone $Command")) {
        if ($RemainingArgs -notcontains "--dry-run") {
            $rcloneArgs += "--dry-run"
        }
    }

    & rclone.exe @rcloneArgs
}

function Add-PathEntry {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,

        [Parameter()]
        [switch]$Prepend
    )

    $Path = (Resolve-Path $Path).Path.TrimEnd("\")

    $currentEntries = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User) -split ";"
    $currentEntries = $currentEntries.ForEach({ $_.TrimEnd("\") })
    if ($currentEntries -contains $Path) {
        Write-Warning "$Path already in PATH."
        return
    }

    $newEntries = if ($Prepend) {
        @($Path) + $currentEntries
    }
    else {
        $currentEntries + @($Path)
    }

    if ($PSCmdlet.ShouldProcess("PATH", "$(if ($Prepend) { 'Prepend' } else { 'Append' }) $Path")) {
        [Environment]::SetEnvironmentVariable("Path", $newEntries -join ";", [EnvironmentVariableTarget]::User)
    }
}

function ConvertTo-WslPath {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    $PSNativeCommandUseErrorActionPreference = $true

    wsl wslpath -a -u $Path.Replace("\", "\\")
}
