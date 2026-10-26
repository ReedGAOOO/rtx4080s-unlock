param([ValidateSet('Status','Install','ConfirmBoot','Disable','PolicyOnly')][string]$Mode='Status')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$InstallRoot='C:\ProgramData\RTXUnlock\v060'
$VolumeRoot='\\?\Volume{00000000-0000-0000-0000-000000000000}\'
$StageRoot=$VolumeRoot+'RTX-AUTO60'
$TaskName='RTXUnlock-v060-ConfirmBoot'
$Token="RTX-AUTO-060-2702-f00dbaad"+[char]13+[char]10
$Marker="RTX-UEFI-FIXED-V1-f00dbaad-2048-1048576"+[char]13+[char]10
$StatePath=Join-Path $InstallRoot 'state.json'

function Assert-True($Value,[string]$Message) {if(-not $Value){throw $Message}}
function Save-Json($Object,[string]$Path) {
    $text=$Object|ConvertTo-Json -Depth 16
    $tmp=$Path+'.new'
    [IO.File]::WriteAllText($tmp,$text,[Text.UTF8Encoding]::new($false))
    if([IO.File]::Exists($Path)){[IO.File]::Replace($tmp,$Path,[NullString]::Value)}else{[IO.File]::Move($tmp,$Path)}
}
function Get-BootStamp { (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime().ToString('o') }
function Get-Hash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Check-RunFiles([string]$RunPath) {
    $files=@(Get-ChildItem -LiteralPath $RunPath -Force)
    Assert-True ($files.Count -eq 1 -and $files[0].Name -ceq 'REPORT.TXT' -and -not $files[0].PSIsContainer) 'Unexpected capture directory contents'
    Assert-True (($files[0].Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'Report must not be a link'
}
function Check-Pending([string]$Lock,[string]$Report) {
    Assert-True ($Lock -cmatch '\ARTX-AUTO-060 PENDING (RUN[0-9]{3})\r\n\z') 'Invalid pending record'
    $run=$Matches[1]
    Assert-True ($Report.Length -lt 131072) 'Report oversized'
    Assert-True ($Report.StartsWith("RTX4080 SUPER 2702 automatic candidate v0.6.2"+[char]10+$run+[char]10)) 'Report/run mismatch'
    $required=@(
        'transaction result=0 containment=0 started=1 quiesced=1 fault=0 retained=0 maps=0 FLR=1',
        'POST-FLR SS0=0x88888888 SS1=0x00000008',
        'POST-GOP SS0=0x88888888 SS1=0x00000008',
        'FINAL status=0 stage=post-unlock-handoff attempted=1 driver_release=1 clean=1'
    )
    foreach($line in $required){Assert-True ($Report -cmatch ('(?m)^'+[regex]::Escape($line)+'\r?$')) ('Missing success gate: '+$line)}
    Assert-True (([regex]::Matches($Report,'(?m)^FINAL ')).Count -eq 1) 'Ambiguous final result'
    Assert-True ($Report -notmatch '(?m)^STOP:') 'STOP in report'
    return $run
}
function Check-HealthResult($Result) {
    Assert-True ($Result.Cells -eq 270336 -and $Result.Mismatches -eq 0) 'CUDA output incorrect'
    Assert-True ($Result.Tflops.Count -eq 5) 'Incomplete CUDA probe'
    foreach($rate in $Result.Tflops){Assert-True (-not [double]::IsNaN($rate) -and -not [double]::IsInfinity($rate) -and $rate -gt 0) 'Invalid CUDA rate'}
    Assert-True (-not [double]::IsNaN($Result.MedianTflops) -and $Result.MedianTflops -ge 150 -and $Result.MedianTflops -lt 400) 'Unlock throughput not confirmed'
}
function Check-BootPolicy($State,[int]$Current,$Next,[string]$Stamp) {
    Assert-True ($State.Phase -eq 'active') 'Automatic unlock is disabled or blocked'
    Assert-True ($Stamp -ne $State.InitialBoot) 'Still on installation boot'
    Assert-True ($Stamp -ne $State.LastAcknowledgedBoot) 'This Windows boot already acknowledged'
    Assert-True ($Current -eq $State.BootId) 'Windows did not start through owned unlock entry'
    Assert-True ($null -eq $Next) 'Another BootNext is pending; leaving it untouched'
}
function Need-Admin {
    $p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    Assert-True ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) 'Administrator rights required'
}
function Load-Firmware {
    if(-not ('RtxFirmware' -as [type])){Add-Type -Path (Join-Path $PSScriptRoot 'Firmware.cs')}
    [RtxFirmware]::EnablePrivilege()
}
function Read-Word([string]$Name) {
    $b=[RtxFirmware]::Read($Name); if($null -eq $b){return $null}
    Assert-True ($b.Length -eq 2) ('Invalid '+$Name)
    return [BitConverter]::ToUInt16($b,0)
}
function Check-SecureBoot {
    $sb=[RtxFirmware]::Read('SecureBoot');$setup=[RtxFirmware]::Read('SetupMode')
    Assert-True ($null -ne $sb -and $sb.Length -eq 1 -and $sb[0] -eq 1) 'Secure Boot not enabled'
    Assert-True ($null -ne $setup -and $setup.Length -eq 1 -and $setup[0] -eq 0) 'SetupMode not zero'
}
function Check-Partition {
    $p=@(Get-Partition | Where-Object {$_.Offset -eq 1048576 -and $_.Size -eq 536870912})
    Assert-True ($p.Count -eq 1) 'Pinned partition missing/ambiguous'
    $d=Get-Disk -Number $p[0].DiskNumber
    Assert-True ($d.Signature -eq 4027431597 -and $d.Size -eq 512110190592 -and -not $d.IsBoot -and -not $d.IsSystem) 'Disk identity mismatch'
    Assert-True (($d.UniqueId -replace '\s','').ToLowerInvariant() -eq 'REPLACE_WITH_LOCAL_DISK_UNIQUE_ID') 'Disk unique ID mismatch'
    Assert-True ($p[0].PartitionNumber -eq 2 -and $p[0].MbrType -eq 239) 'Partition identity mismatch'
    $volume=$p[0]|Get-Volume
    Assert-True ($volume.FileSystem -eq 'FAT32' -and $volume.FileSystemLabel -eq 'RTX-UEFI') 'Partition filesystem mismatch'
    Assert-True ([IO.File]::ReadAllText($VolumeRoot+'RTX-UEFI-COLLECT.OK') -ceq $Marker) 'Partition marker mismatch'
}
function Check-Hashes($Manifest,[string]$HostRoot) {
    foreach($entry in $Manifest.Host.PSObject.Properties){
        Assert-True ($entry.Name -match '^[a-zA-Z0-9_.-]+$') 'Invalid host filename'
        Assert-True ((Get-Hash (Join-Path $HostRoot $entry.Name)) -eq $entry.Value) ('Host hash mismatch: '+$entry.Name)
    }
    foreach($entry in $Manifest.Stage.PSObject.Properties){
        Assert-True ($entry.Name -match '^(ASSETS\\)?[a-zA-Z0-9_.-]+$') 'Invalid stage filename'
        Assert-True ((Get-Hash (Join-Path $StageRoot $entry.Name)) -eq $entry.Value) ('EFI/asset hash mismatch: '+$entry.Name)
    }
}
function Check-Gpu {
    $gpu=@(Get-CimInstance Win32_VideoController | Where-Object {$_.PNPDeviceID -match '^PCI\\VEN_10DE&DEV_2702&SUBSYS_18CC10DE'})
    Assert-True ($gpu.Count -eq 1) 'Exact RTX GPU missing/ambiguous'
    Assert-True ($gpu[0].ConfigManagerErrorCode -eq 0 -and $gpu[0].DriverVersion -eq '32.0.16.1742') 'GPU error or driver changed'
    $uuid=& "$env:SystemRoot\System32\nvidia-smi.exe" --query-gpu=uuid --format=csv,noheader
    Assert-True ($LASTEXITCODE -eq 0 -and @($uuid).Count -eq 1 -and $uuid.Trim() -eq 'GPU-00000000-0000-0000-0000-000000000000') 'GPU UUID mismatch'
}
function Check-Events {
    $boot=(Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $ms=[Math]::Ceiling(((Get-Date)-$boot).TotalMilliseconds)
    # Empty results allowed; inaccessible System log is not treated as success.
    $query="*[System[TimeCreated[timediff(@SystemTime) <= $ms] and ((Provider[@Name='Display'] and EventID=4101) or (Provider[@Name='nvlddmkm'] and (Level=1 or Level=2)) or (Provider[@Name='Microsoft-Windows-WHEA-Logger'] and Level=2))]]"
    $q=[Diagnostics.Eventing.Reader.EventLogQuery]::new('System',[Diagnostics.Eventing.Reader.PathType]::LogName,$query)
    $reader=[Diagnostics.Eventing.Reader.EventLogReader]::new($q)
    try{$evtRecord=$reader.ReadEvent();if($null -ne $evtRecord){try{throw ('GPU/system hardware error event '+$evtRecord.Id)}finally{$evtRecord.Dispose()}}}finally{$reader.Dispose()}
}
function Protect-Directory([string]$Path) {
    $acl=[Security.AccessControl.DirectorySecurity]::new()
    $acl.SetAccessRuleProtection($true,$false)
    foreach($s in @('S-1-5-18','S-1-5-32-544')){
        $id=[Security.Principal.SecurityIdentifier]::new($s)
        $rule=[Security.AccessControl.FileSystemAccessRule]::new($id,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
        $acl.AddAccessRule($rule)
    }
    $read=[Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-5-32-545'),'ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow')
    $acl.AddAccessRule($read)
    Set-Acl -LiteralPath $Path -AclObject $acl
}
function Check-OwnedOption($State) {
    $name='Boot{0:X4}' -f [int]$State.BootId
    Assert-True ([RtxFirmware]::Equal([RtxFirmware]::Read($name),[Convert]::FromBase64String($State.OptionBase64))) 'Owned firmware option changed'
}
function Queue-Next($State) {
    Check-OwnedOption $State
    Assert-True ($null -eq (Read-Word 'BootNext')) 'Existing BootNext will not be overwritten'
    [RtxFirmware]::Write('BootNext',[BitConverter]::GetBytes([uint16]$State.BootId))
}
function Load-State {[IO.File]::ReadAllText($StatePath,[Text.Encoding]::UTF8) | ConvertFrom-Json}
function Save-State($State) {Save-Json $State $StatePath}

if($Mode -eq 'PolicyOnly'){return}
if($Mode -eq 'Status'){
    if(Test-Path -LiteralPath $StatePath){Get-Content -LiteralPath $StatePath -Raw}else{'Not installed'}
    return
}
throw 'Public reference: configure and independently review a local profile before deployment. See docs/PORTING.md.'
Need-Admin
$mutex=[Threading.Mutex]::new($false,'Global\RTXUnlock_v060')
$acquired=$false
try{
    try{$acquired=$mutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$acquired=$true}
    Assert-True $acquired 'Another RTXUnlock operation is running'
    if($Mode -eq 'Install'){
        Assert-True (-not (Test-Path -LiteralPath $InstallRoot)) 'Already installed; refusing overwrite'
        $manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
        Check-Partition
        Check-Hashes $manifest $PSScriptRoot
        Assert-True (-not [IO.File]::Exists($StageRoot+'\ATTEMPT.LCK')) 'Pending attempt exists'
        Assert-True ([IO.File]::ReadAllText($StageRoot+'\AUTO.OFF') -ceq $Token) 'Inactive token mismatch'
        Assert-True (-not [IO.File]::Exists($StageRoot+'\AUTO.ON')) 'Token already enabled'
        Assert-True ($null -eq (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) 'Task already exists'
        Load-Firmware;Check-SecureBoot;Check-Gpu
        Assert-True ($null -eq (Read-Word 'BootNext')) 'Existing BootNext: stop without changes'
        $order=[RtxFirmware]::Read('BootOrder')
        Assert-True ($null -ne $order -and $order.Length -ge 2 -and $order.Length%2 -eq 0) 'Invalid BootOrder'
        $used=@();$windows=$false
        for($i=0;$i -lt $order.Length;$i+=2){
            $id=[BitConverter]::ToUInt16($order,$i);$used+=$id
            $opt=[RtxFirmware]::Read(('Boot{0:X4}' -f $id))
            if($null -ne $opt -and [Text.Encoding]::Unicode.GetString($opt) -match '(?i)\\EFI\\Microsoft\\Boot\\bootmgfw.efi'){$windows=$true}
        }
        Assert-True $windows 'Original BootOrder does not include Windows Boot Manager'
        $bootId=$null
        foreach($id in 0x7A60..0x7A6F){if($id -notin $used -and $null -eq [RtxFirmware]::Read(('Boot{0:X4}' -f $id))){$bootId=$id;break}}
        Assert-True ($null -ne $bootId) 'No unused reserved Boot option'
        $option=[RtxFirmware]::LoadOption()
        $user=[Security.Principal.WindowsIdentity]::GetCurrent().Name
        $state=[pscustomobject]@{Version='0.6.2';Phase='active';BootId=$bootId;OptionBase64=[Convert]::ToBase64String($option);OriginalBootOrderBase64=[Convert]::ToBase64String($order);OriginalBootCurrent=(Read-Word 'BootCurrent');InitialBoot=(Get-BootStamp);LastAcknowledgedBoot=$null;LastRun=$null;LastResult='installation-in-progress';InstalledAt=(Get-Date).ToString('o');User=$user;ConfirmedBoots=0}
        $parent=Split-Path $InstallRoot
        if(-not (Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent|Out-Null}
        Assert-True (((Get-Item -LiteralPath $parent -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'Install parent must not be a link'
        Protect-Directory $parent
        New-Item -ItemType Directory -Path $InstallRoot | Out-Null
        Protect-Directory $InstallRoot
        foreach($entry in $manifest.Host.PSObject.Properties){Copy-Item -LiteralPath (Join-Path $PSScriptRoot $entry.Name) -Destination (Join-Path $InstallRoot $entry.Name)}
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Destination $InstallRoot
        Save-State $state
        $keys=@{}
        foreach($name in @('PK','KEK','db','dbx')){$key=Get-SecureBootUEFI -Name $name;$keys[$name]=[Convert]::ToBase64String($key.Bytes)}
        Save-Json $keys (Join-Path $InstallRoot 'secureboot-backup.json')
        $action=New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument ('-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$InstallRoot+'\AutoUnlock.ps1" -Mode ConfirmBoot') -WorkingDirectory $InstallRoot
        $trigger=New-ScheduledTaskTrigger -AtLogOn -User $user;$trigger.Delay='PT30S'
        $principal=New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
        $settings=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 3) -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Confirm RTX unlock and queue the next one-time UEFI boot; never change BootOrder.' | Out-Null
        try{
            [RtxFirmware]::Write(('Boot{0:X4}' -f $bootId),$option)
            Assert-True ([RtxFirmware]::Equal($order,[RtxFirmware]::Read('BootOrder'))) 'Firmware unexpectedly changed BootOrder'
            [IO.File]::Move($StageRoot+'\AUTO.OFF',$StageRoot+'\AUTO.ON')
            Queue-Next $state
            $state.LastResult='installed-next-boot-queued-unvalidated';Save-State $state
            $state|ConvertTo-Json -Depth 8
        }catch{
            $state.Phase='blocked';$state.LastResult=$_.Exception.Message
            try{Save-State $state}finally{
                [RtxFirmware]::EnablePrivilege()
                if((Read-Word 'BootNext') -eq $bootId){[RtxFirmware]::Write('BootNext',$null)}
                if([IO.File]::Exists($StageRoot+'\AUTO.ON') -and -not [IO.File]::Exists($StageRoot+'\AUTO.OFF')){[IO.File]::Move($StageRoot+'\AUTO.ON',$StageRoot+'\AUTO.OFF')}
            }
            throw
        }
        return
    }
    Assert-True ($PSScriptRoot -eq $InstallRoot) 'Run installed host script'
    $state=Load-State
    $manifest=Get-Content -LiteralPath (Join-Path $InstallRoot 'manifest.json') -Raw|ConvertFrom-Json
    if($Mode -eq 'Disable'){
        Load-Firmware
        $state.Phase='disabled';$state.LastResult='disabled-by-user';Save-State $state
        $task=Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if($null -ne $task){Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false}
        if((Read-Word 'BootNext') -eq $state.BootId){[RtxFirmware]::Write('BootNext',$null)}
        Check-OwnedOption $state
        [RtxFirmware]::Write(('Boot{0:X4}' -f [int]$state.BootId),$null)
        Check-Partition
        if([IO.File]::Exists($StageRoot+'\AUTO.ON') -and -not [IO.File]::Exists($StageRoot+'\AUTO.OFF')){[IO.File]::Move($StageRoot+'\AUTO.ON',$StageRoot+'\AUTO.OFF')}
        'Disabled. BootOrder unchanged. Files and logs retained.'
        return
    }
    if($state.Phase -ne 'active'){return}
    $stamp=Get-BootStamp
    if($stamp -eq $state.InitialBoot -or $stamp -eq $state.LastAcknowledgedBoot){return}
    try{
        Load-Firmware
        Check-BootPolicy $state (Read-Word 'BootCurrent') (Read-Word 'BootNext') $stamp
        Check-OwnedOption $state;Check-SecureBoot;Check-Partition
        Check-Hashes $manifest $InstallRoot
        Assert-True ([IO.File]::ReadAllText($StageRoot+'\AUTO.ON') -ceq $Token) 'Automatic token disabled'
        $lockPath=$StageRoot+'\ATTEMPT.LCK'
        $lock=[IO.File]::ReadAllText($lockPath)
        Assert-True ($lock -cmatch '\ARTX-AUTO-060 PENDING (RUN[0-9]{3})\r\n\z') 'Invalid attempt record'
        $run=$Matches[1]
        $reportPath=$StageRoot+'\'+$run+'\REPORT.TXT'
        Assert-True ((Get-Item -LiteralPath $reportPath).Length -lt 131072) 'Report oversized'
        $report=[IO.File]::ReadAllText($reportPath)
        $null=Check-Pending $lock $report
        Check-RunFiles ($StageRoot+'\'+$run)
        Check-Gpu;Check-Events
        if(-not ('RtxCudaProbe' -as [type])){Add-Type -Path (Join-Path $InstallRoot 'CudaProbe.cs')}
        $result=[RtxCudaProbe]::Run((Join-Path $InstallRoot 'tensor_modes_issue_sm89.cubin'))
        Check-HealthResult $result
        $archive=Join-Path $InstallRoot ('confirmed-{0:D6}-{1}' -f ([int]$state.ConfirmedBoots+1),$run)
        Assert-True (-not (Test-Path -LiteralPath $archive)) 'Run already archived'
        New-Item -ItemType Directory -Path $archive | Out-Null
        [IO.File]::WriteAllText((Join-Path $archive 'REPORT.TXT'),$report,[Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText((Join-Path $archive 'ATTEMPT.LCK'),$lock,[Text.Encoding]::ASCII)
        Save-Json ([ordered]@{Boot=$stamp;Gpu=$result;ReportSha256=(Get-Hash $reportPath);Time=(Get-Date).ToString('o')}) (Join-Path $archive 'health.json')
        Check-BootPolicy $state (Read-Word 'BootCurrent') (Read-Word 'BootNext') $stamp
        Assert-True ([IO.File]::ReadAllText($lockPath) -ceq $lock) 'Pending record changed during validation'
        Assert-True ((Get-Hash $reportPath) -eq (Get-Hash (Join-Path $archive 'REPORT.TXT'))) 'Report changed during validation'
        $state.LastAcknowledgedBoot=$stamp;$state.LastRun=$run;$state.ConfirmedBoots++;$state.LastResult='health-passed';Save-State $state
        # Only this new package's exact lock is removed, after durable evidence and validation.
        [IO.File]::Delete($lockPath)
        Assert-True (-not [IO.File]::Exists($lockPath)) 'Unable to clear confirmed pending record'
        # Local 2702 profile emits REPORT.TXT only; it verifies PROM in memory.
        # Archive the verified successful report, then recycle only that exact file.
        # No recursive deletion; unexpected files cause a safe stop.
        Check-RunFiles ($StageRoot+'\'+$run)
        [IO.File]::Delete($reportPath)
        [IO.Directory]::Delete(($StageRoot+'\'+$run),$false)
        Queue-Next $state
        $state.LastResult='confirmed-next-boot-queued';Save-State $state
    }catch{
        $state.Phase='blocked';$state.LastResult=$_.Exception.Message;Save-State $state
        throw
    }
}finally{if($acquired){$mutex.ReleaseMutex()};$mutex.Dispose()}
