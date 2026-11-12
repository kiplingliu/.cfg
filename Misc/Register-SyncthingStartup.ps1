$s = (New-Object -ComObject WScript.Shell).CreateShortcut("$([Environment]::GetFolderPath('Startup'))\Syncthing.lnk")
$s.TargetPath = "$env:WINDIR\System32\conhost.exe"
$s.Arguments  = '--headless syncthing --no-console --no-browser'
$s.Save()
