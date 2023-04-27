$localRepoPath = git rev-parse --show-toplevel

$cfvRepoPath = $($localRepoPath | Split-Path -Parent) + "\M365CallFlowVisualizer"

Set-Location $cfvRepoPath

$allAutoAttendants = $null
$allCallQueues = $null
$allResourceAccounts = $null

. .\AllTopLevelVoiceAppsToMarkdownDocFx.ps1

Set-Location $localRepoPath