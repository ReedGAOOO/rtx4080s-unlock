$ErrorActionPreference='Stop'
$a=$PSScriptRoot
. (Join-Path $a 'host\AutoUnlock.ps1') -Mode PolicyOnly
$checks=[Collections.Generic.List[string]]::new()
function Pass([string]$Name,[scriptblock]$Test){& $Test;$checks.Add($Name)}
function Reject([string]$Name,[scriptblock]$Test){
    $failed=$false
    try{& $Test|Out-Null}catch{$failed=$true}
    if(-not $failed){throw ('FAIL: accepted '+$Name)}
    $checks.Add($Name)
}
$lock="RTX-AUTO-060 PENDING RUN002"+[char]13+[char]10
$report=@(
 'RTX4080 SUPER 2702 automatic candidate v0.6.2'
 'RUN002'
 'transaction result=0 containment=0 started=1 quiesced=1 fault=0 retained=0 maps=0 FLR=1'
 'POST-FLR SS0=0x88888888 SS1=0x00000008'
 'POST-GOP SS0=0x88888888 SS1=0x00000008'
 'FINAL status=0 stage=post-unlock-handoff attempted=1 driver_release=1 clean=1'
) -join [char]10
Pass 'complete verified run' {Assert-True ((Check-Pending $lock $report) -eq 'RUN002') 'Unexpected run'}
foreach($bad in @('','RTX-AUTO-060 PENDING RUN002',"RTX-AUTO-060 PENDING RUN../"+[char]13+[char]10,($lock+'extra'),($lock-replace 'RUN002','RUN02'))){
 Reject ('invalid pending '+$checks.Count) {Check-Pending $bad $report}
}
Reject 'wrong run' {Check-Pending ($lock -replace '002','003') $report}
Reject 'old build' {Check-Pending $lock ($report-replace '0.6.2','0.6.0')}
Reject 'bad selectors' {Check-Pending $lock ($report-replace '88888888','33562110')}
Reject 'cleanup error' {Check-Pending $lock ($report-replace 'clean=1','clean=0')}
Reject 'transaction error' {Check-Pending $lock ($report-replace 'transaction result=0','transaction result=-1')}
Reject 'retained DMA' {Check-Pending $lock ($report-replace 'retained=0','retained=1')}
Reject 'unreleased driver' {Check-Pending $lock ($report-replace 'driver_release=1','driver_release=0')}
Reject 'no attempt' {Check-Pending $lock ($report-replace 'attempted=1','attempted=0')}
Reject 'ambiguous FINAL' {Check-Pending $lock ($report+[char]10+'FINAL status=0')}
Reject 'STOP present' {Check-Pending $lock ($report+[char]10+'STOP: cleanup')}
Reject 'oversized' {Check-Pending $lock ($report+('x'*131072))}
$health=[pscustomobject]@{Cells=270336;Mismatches=0;MedianTflops=188.0;Tflops=@(180.,190.,188.,191.,187.)}
Pass 'healthy CUDA' {Check-HealthResult $health}
Reject 'incorrect output' {$v=$health.PSObject.Copy();$v.Mismatches=1;Check-HealthResult $v}
Reject 'missing output' {$v=$health.PSObject.Copy();$v.Cells=0;Check-HealthResult $v}
Reject 'half-rate CUDA' {$v=$health.PSObject.Copy();$v.MedianTflops=103.;Check-HealthResult $v}
Reject 'NaN CUDA' {$v=$health.PSObject.Copy();$v.MedianTflops=[double]::NaN;Check-HealthResult $v}
Reject 'invalid timing' {$v=$health.PSObject.Copy();$v.Tflops=@(-1.,180.,181.,180.,180.);Check-HealthResult $v}
$state=[pscustomobject]@{Phase='active';InitialBoot='initial';LastAcknowledgedBoot='previous';BootId=0x7A60}
Pass 'fresh owned boot' {Check-BootPolicy $state 0x7A60 $null 'current'}
Reject 'installation boot' {Check-BootPolicy $state 0x7A60 $null 'initial'}
Reject 'repeated acknowledgment' {Check-BootPolicy $state 0x7A60 $null 'previous'}
Reject 'Windows fallback no rearm' {Check-BootPolicy $state 1 $null 'current'}
Reject 'other next boot preserved' {Check-BootPolicy $state 0x7A60 5 'current'}
Reject 'owned already queued' {Check-BootPolicy $state 0x7A60 0x7A60 'current'}
Reject 'disabled no rearm' {$v=$state.PSObject.Copy();$v.Phase='disabled';Check-BootPolicy $v 0x7A60 $null 'current'}
$testRoot=Join-Path $a 'local'
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$jsonTest=Join-Path $testRoot 'state-replace-test.json'
$runFixture=Join-Path $testRoot ('capture-policy-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runFixture|Out-Null
Pass 'actual report-only local capture accepted without PROM' {
    Copy-Item -LiteralPath (Join-Path $a 'evidence\v062-success-excerpt.txt') -Destination (Join-Path $runFixture 'REPORT.TXT')
    Check-RunFiles $runFixture
}
Reject 'unexpected capture files retained' {
    [IO.File]::WriteAllText((Join-Path $runFixture 'UNEXPECTED.TXT'),'preserve')
    Check-RunFiles $runFixture
}
Pass 'capture check never deletes artifacts' {
    Assert-True ([IO.File]::Exists((Join-Path $runFixture 'REPORT.TXT'))) 'Report missing'
    Assert-True ([IO.File]::Exists((Join-Path $runFixture 'UNEXPECTED.TXT'))) 'Unexpected file removed'
}
Pass 'atomic JSON create/update' {
    Save-Json @{Generation=1} $jsonTest
    Save-Json @{Generation=2} $jsonTest
    Assert-True ((Get-Content -LiteralPath $jsonTest -Raw|ConvertFrom-Json).Generation -eq 2) 'Atomic replacement failed'
}
Pass 'localized UTF8 state is readable on Windows PowerShell 5.1' {
    $priorStatePath=$StatePath
    try {
        $StatePath=$jsonTest
        $localized=([string][char]0x663e)+([string][char]0x5361)+([string][char]0x201c)+'error'+([string][char]0x201d)
        Save-Json @{LastResult=$localized;Phase='blocked'} $StatePath
        Assert-True ((Load-State).LastResult -ceq $localized) 'UTF8 state corrupted'
    } finally {$StatePath=$priorStatePath}
}
Add-Type -Path (Join-Path $a 'host\Firmware.cs')
Add-Type -Path (Join-Path $a 'host\CudaProbe.cs')
$option=[RtxFirmware]::LoadOption()
$evidence=Join-Path $a 'local'
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
Save-Json ([ordered]@{Passed=$checks.Count;Names=$checks;FirmwareReadOrWriteCalled=$false;Time=(Get-Date).ToString('o');LoadOptionBase64=[Convert]::ToBase64String($option)}) (Join-Path $evidence 'host-policy-tests.json')
$checks.Count.ToString()+' host policy tests passed; no firmware API called.'
