$pwshPath = (Get-Command pwsh.exe).Source
$command  = "Sync-Backup -ShouldCheckLastSync -Verbose *>&1 | Out-File -FilePath '$HOME\sync-backup.log' -Append"

$service = New-Object -ComObject Schedule.Service
$service.Connect()

$task = $service.NewTask(0)
$task.RegistrationInfo.Description = "SyncBackup"

# Settings: Allow battery execution
$task.Settings.DisallowStartIfOnBatteries = $false
$task.Settings.StopIfGoingOnBatteries = $false

# Trigger: Workstation Unlock (Type 11), 30s delay
$trigger = $task.Triggers.Create(11) # 11 = TASK_TRIGGER_SESSION_STATE_CHANGE
$trigger.StateChange = 8             # 8  = TASK_SESSION_UNLOCK
$trigger.Delay = "PT30S"

# Action: Execute pwsh (Type 0 = TASK_ACTION_EXEC)
$action = $task.Actions.Create(0)
$action.Path = $pwshPath
$action.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$command`""

# Register: Flag 6 = TASK_CREATE_OR_UPDATE, LogonType 3 = TASK_LOGON_INTERACTIVE_TOKEN
$rootFolder = $service.GetFolder("\")
$rootFolder.RegisterTaskDefinition("SyncBackup", $task, 6, $null, $null, 3) | Out-Null
