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

function Save-GitSnapshot {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$RepoPath,

        [Parameter()]
        [string]$BundlePath
    )

    $PSNativeCommandUseErrorActionPreference = $true

    Push-Location $RepoPath
    try {
        if (git status --porcelain) {
            if ($PSCmdlet.ShouldProcess($RepoPath, "Commit all uncommitted changes")) {
                git add .
                git -c user.name="Laptop Bot" -c user.email="bot@localhost" commit -m "Automated snapshot"
            }
        }
        else {
            Write-Verbose "No changes since last commit in $RepoPath."
        }
        if ($BundlePath) {
            $isBundleNewer = $false

            if (Test-Path $BundlePath) {
                $lastCommitTime = [DateTimeOffset]::Parse((git log -1 --format="%cI")).UtcDateTime
                $bundleMtime = (Get-Item $BundlePath).LastWriteTimeUtc
                $isBundleNewer = $bundleMtime -gt $lastCommitTime
            }

            if (-not $isBundleNewer -and $PSCmdlet.ShouldProcess($BundlePath, "Create git bundle")) {
                git bundle create $BundlePath --all
            }
        }
    }
    finally {
        Pop-Location
    }
}

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

    if (-not $PSCmdlet.ShouldProcess("rclone $Command $RemainingArgs")) {
        if ($RemainingArgs -notcontains "--dry-run") {
            $rcloneArgs += "--dry-run"
        }
    }

    rclone @rcloneArgs
}

function Export-VSCodeExtensions {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path
    )

    $PSNativeCommandUseErrorActionPreference = $true

    if ($PSCmdlet.ShouldProcess($Path, "Save VS Code extension list")) {
        code --list-extensions > "$Path\vscode-extensions.win.txt"
        wsl code --list-extensions > "$Path\vscode-extensions.wsl.txt"
    }
}

function Sync-Backup {
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter()]
        [switch]$ShouldCheckLastSync
    )

    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $true

    $lastSyncPath = "$HOME\last-sync.txt"
    $maxDaysSinceLastSync = 1

    if ($ShouldCheckLastSync) {
        if (Test-Path $lastSyncPath) {
            $lastSyncTime = (Get-Item $lastSyncPath).LastWriteTimeUtc
            $currentTime = Get-Date -AsUTC
            if (($currentTime - $lastSyncTime).TotalDays -lt $maxDaysSinceLastSync) {
                Write-Verbose "Not backing up; last sync was < $maxDaysSinceLastSync days ago ($lastSyncTime)."
                return
            }
        }
    }

    $notesDir = "$HOME\Notes"
    $backupDir = "$HOME\Personal"
    $remote = "mega"
    $miscConfigDir = "$HOME\Misc"

    Save-GitSnapshot $notesDir -BundlePath "$backupDir\Notes.bundle" -Verbose:($VerbosePreference -eq "Continue")
    Invoke-Rclone sync -v $backupDir "${remote}:$([IO.Path]::GetFileName($backupDir))" -Verbose:($VerbosePreference -eq "Continue")
    Export-VSCodeExtensions $miscConfigDir -Verbose:($VerbosePreference -eq "Continue")

    if ($PSCmdlet.ShouldProcess($lastSyncPath, "Update last sync timestamp")) {
        if (Test-Path $lastSyncPath) {
            (Get-Item $lastSyncPath).LastWriteTime = Get-Date
        }
        else {
            $null = New-Item -Path $lastSyncPath -ItemType "File"
        }
    }

    Write-Verbose "Backup completed successfully."
}
