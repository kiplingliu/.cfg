$wslGitConfigContent = @"
[include]
`tpath = $(ConvertTo-WslPath $HOME\.gitconfig)
[core]
`tautocrlf = input
[credential]
`thelper =
`thelper = "$(ConvertTo-WslPath $HOME\scoop\apps\git\current\mingw64\bin\git-credential-manager.exe)"

"@

$wslGitConfigContent.Replace("`r`n", "`n") | Set-Content -Path "$(wsl wslpath -w "~")\.gitconfig" -NoNewline
