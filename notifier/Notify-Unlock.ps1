param([switch]$PolicyOnly,[switch]$CheckOnly)
$ErrorActionPreference='Stop'
function Get-UnlockDecision($State,[datetime]$BootUtc) {
    if($null -eq $State){return 'pending'}
    if($State.Phase -eq 'disabled'){return 'disabled'}
    if($State.Phase -eq 'blocked'){return 'blocked'}
    try {
        $ack=[datetimeoffset]::Parse([string]$State.LastAcknowledgedBoot)
        if($State.Phase -eq 'active' -and $ack.UtcDateTime -eq $BootUtc -and
            $State.LastResult -eq 'confirmed-next-boot-queued'){return 'success'}
    }catch{}
    return 'pending'
}
if($PolicyOnly){return}
$StatePath='C:\ProgramData\RTXUnlock\v060\state.json'
$LocalRoot=Join-Path $env:LOCALAPPDATA 'RTXUnlockNotifier'
$WarningPath=Join-Path $LocalRoot 'last-warning.json'
$boot=(Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime()
$stamp=$boot.ToString('o')
function Read-CurrentState {
    try {Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json}catch{return $null}
}
if($CheckOnly){Get-UnlockDecision (Read-CurrentState) $boot;return}
$mutex=[Threading.Mutex]::new($false,'Local\RTXUnlockFailureNotifier')
$acquired=$false
try {
    $acquired=$mutex.WaitOne(0)
    if(-not $acquired){return}
    try {
        $previous=Get-Content -LiteralPath $WarningPath -Raw | ConvertFrom-Json
        if($previous.Boot -eq $stamp){return}
    }catch{}
    # The existing health task starts 30s after logon and has a 3-minute limit.
    # This watcher only reads its state; it never runs CUDA or firmware code.
    $watch=[Diagnostics.Stopwatch]::StartNew()
    do {
        $state=Read-CurrentState
        $decision=Get-UnlockDecision $state $boot
        if($decision -in @('success','disabled')){return}
        if($decision -eq 'blocked' -and $watch.Elapsed.TotalSeconds -ge 45){break}
        if($watch.Elapsed.TotalSeconds -ge 240){break}
        Start-Sleep -Seconds 10
    }while($true)
    # Re-read immediately before warning to avoid a completion race.
    $state=Read-CurrentState
    $decision=Get-UnlockDecision $state $boot
    if($decision -in @('success','disabled')){return}
    $detail=if($null -eq $state){'无法读取后台验证记录。'}else{[string]$state.LastResult}
    if($detail.Length -gt 600){$detail=$detail.Substring(0,600)}
    $message=if($decision -eq 'blocked'){
        "本次开机的自动解锁流程已停止，尚未确认正常完成。"
    }else{
        "登录后等待约 4 分钟，仍未收到本次开机的解锁验证成功记录。"
    }
    $message+="`r`n`r`n这不等同于显卡损坏。无需立即重启，请将此提示发给助手排查。`r`n`r`n详情：$detail"
    New-Item -ItemType Directory -Path $LocalRoot -Force | Out-Null
    $record=[ordered]@{Boot=$stamp;Time=(Get-Date).ToString('o');Decision=$decision;Detail=$detail}
    [IO.File]::WriteAllText($WarningPath,($record|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
    $shell=New-Object -ComObject WScript.Shell
    $null=$shell.Popup($message,120,'RTX 自动解锁：需要检查',48)
}finally{
    if($acquired){$mutex.ReleaseMutex()}
    $mutex.Dispose()
}
