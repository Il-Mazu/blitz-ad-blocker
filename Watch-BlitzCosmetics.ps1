[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateRange(1024,65535)][int]$Port,
    [Parameter(Mandatory=$true)][int]$BlitzProcessId,
    [switch]$Once
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Cdp.ps1"
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cosmetic-filter.js'))
$allowedHosts = @('blitz.gg','blitzapp.gg','agentselect.net','championselect.net','lolstats.com','probuilds.net','tftcomps.gg')
$statusPath = Join-Path $PSScriptRoot 'cosmetic-status.json'
$lastStatus = ''
function Write-FilterStatus([string]$state, [int]$matches, [string]$detail) {
    $key = "$state|$matches|$detail"
    if ($key -ne $script:lastStatus) {
        @{state=$state; matchedElements=$matches; detail=$detail; updated=(Get-Date).ToString('s')} |
            ConvertTo-Json | Set-Content -LiteralPath $statusPath -Encoding UTF8
        $script:lastStatus = $key
    }
}
do {
    $process = Get-Process -Id $BlitzProcessId -ErrorAction SilentlyContinue
    if (-not $process -or $process.ProcessName -ne 'Blitz') { break }
    try {
        $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 3
        $active = $false
        $count = 0
        foreach ($target in $targets) {
            if ($target.type -ne 'page' -or -not $target.url) { continue }
            $url = [uri]$target.url
            if ($url.Scheme -ne 'https' -or $url.Host -notin $allowedHosts -or $url.AbsolutePath -notmatch '^/v[^/]+/') { continue }
            $socketUri = [uri]$target.webSocketDebuggerUrl
            if ($socketUri.Host -ne '127.0.0.1' -or $socketUri.Port -ne $Port) { continue }
            $reply = Invoke-BlitzCdp $target.webSocketDebuggerUrl 'Runtime.evaluate' @{expression=$source;returnByValue=$true}
            if ($reply.PSObject.Properties['exceptionDetails']) { throw 'The cosmetic filter raised a JavaScript error.' }
            if ($reply.result.PSObject.Properties['value'] -and $reply.result.value.active) {
                $active = $true
                $count += $reply.result.value.matchedElements
            }
        }
        if ($active) { Write-FilterStatus 'active' $count 'Cosmetic CSS installed.' }
        else { Write-FilterStatus 'waiting' 0 'Waiting for the Blitz desktop interface.' }
    } catch {
        Write-FilterStatus 'retrying' 0 'Cannot apply cosmetic filtering yet; retrying while Blitz runs.'
        if ($Once) { throw }
    }
    if (-not $Once) { Start-Sleep -Seconds 3 }
} until ($Once)
if (-not $Once) { Write-FilterStatus 'stopped' 0 'Blitz exited.' }
