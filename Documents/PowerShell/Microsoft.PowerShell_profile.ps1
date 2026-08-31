$PSROptions = @{
    EditMode = "Vi"
    ViModeIndicator = "Cursor"
    BellStyle = "None"
}
Set-PSReadLineOption @PSROptions

# https://stackoverflow.com/a/59125287
if ($env:TERM_PROGRAM -eq "vscode") {
  Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardKillWord
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+Oem4' -Function ViCommandMode
Set-PSReadlineKeyHandler -Key Tab -Function Complete

New-Alias -Name which -Value where.exe
function config { & git --git-dir=$HOME\.cfg\ --work-tree=$HOME @args }

Invoke-Expression (& { (zoxide init powershell | Out-String) })
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

# Explicitly set initial cursor to Blinking Underline (Insert mode default)
Write-Host -NoNewline "`e[3 q"
