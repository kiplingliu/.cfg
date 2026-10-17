# InputEncoding fixes typing non-ASCII into native programs expecting UTF-8
# (e.g. fzf).
#
# OutputEncoding fixes interpretation of native program output.
[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$PSROptions = @{
  EditMode        = "Vi"
  ViModeIndicator = "Cursor"
  BellStyle       = "None"
}
Set-PSReadLineOption @PSROptions

# https://stackoverflow.com/a/59125287
if ($env:TERM_PROGRAM -eq "vscode") {
  Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardKillWord
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+Oem4' -Function ViCommandMode
Set-PSReadlineKeyHandler -Key Tab -Function Complete

# `Set-PSReadlineOption -EditMode ...` resets bindings, so PSFzf module, which
# sets its own bindings, should be imported afterwards
Import-Module PSFzf
$PSFzfOptions = @{
  PSReadlineChordProvider       = 'Ctrl+t'
  PSReadlineChordReverseHistory = 'Ctrl+r'

  # When first loading profile, bindings should be automatically set by PSFzf if
  # they don't conflict w/ existing bindings. However, when reloading profile
  # (`. $PROFILE`), explicit setting below is needed b/c module is not
  # re-imported
  PSReadlineChordSetLocation    = 'Alt+c'

  # EnableFd bug: https://github.com/kelleyma49/PSFzf/issues/175
  #
  # EnableFd = $true
}
Set-PsFzfOption @PSFzfOptions

# Problems occur when path names include wildcard chars, e.g. square brackets:
# see https://github.com/PowerShell/PowerShell/issues/21017. In particular, tab
# completion doesn't work properly unless we use -LiteralPath. The hope was that
# PSFzf could remedy this by providing an alternative completion mechanism.
#
# Unfortunately, PSFzf relies on file-processing cmdlets (e.g. Test-Path) which
# interpret wildcard chars. The settings below rewrite PSFzf code to use literal
# paths.
& (Get-Module PSFzf) {
  $name = 'Invoke-FzfPsReadlineHandlerProvider'
  $body = (Get-Command $name -CommandType Function).Definition

  $replacements = @{
    'Test-Path $currentPath'    = 'Test-Path -LiteralPath $currentPath'
    'Resolve-Path $currentPath' = 'Resolve-Path -LiteralPath $currentPath'
  }

  foreach ($old in $replacements.Keys) {
    $new = $replacements[$old]

    if ($body.Contains($old)) {
      $body = $body.Replace($old, $new)
    }
    elseif (-not $body.Contains($new)) {
      throw "PSFzf handler changed: cannot safely patch '$old'."
    }
  }

  Set-Item -Path "Function:script:$name" -Value (
    [scriptblock]::Create($body)
  )
}
Set-PsFzfOption -AltCCommand {
  param($Location)
  Set-Location -LiteralPath $Location
}

Set-Alias -Name which -Value where.exe
Set-Alias -Name touch -Value New-Item
function config { git --git-dir=$HOME\.cfg\ --work-tree=$HOME @args }

Invoke-Expression (& { (zoxide init powershell | Out-String) })
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

# Explicitly set initial cursor to Blinking Underline (Insert mode default)
Write-Host -NoNewline "`e[3 q"
