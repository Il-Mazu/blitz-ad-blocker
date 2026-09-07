[CmdletBinding()]
param(
    [string]$BlitzPath = "$env:LOCALAPPDATA\Programs\Blitz\Blitz.exe",
    [switch]$Check,
    [switch]$NoCosmetics
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-BlockRules {
    param([string]$ListPath)
    $domains = @(Get-Content -LiteralPath $ListPath | ForEach-Object {
        $domain = ($_ -split '#', 2)[0].Trim().ToLowerInvariant()
        if ($domain) {
            if ($domain.Length -gt 253 -or $domain -notmatch '^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$') {
                throw "Invalid domain in blocklist: $domain"
            }
            # Protect game, sign-in, and the app's own content services.
            foreach ($allowed in @('blitz.gg', 'riotgames.com', 'leagueoflegends.com', 'riotcdn.net')) {
                if ($domain -eq $allowed -or $domain.EndsWith('.' + $allowed) -or $allowed.EndsWith('.' + $domain)) {
                    throw "Refusing to block a protected application/game domain: $domain"
                }
            }
            $domain
        }
    } | Sort-Object -Unique)
    if ($domains.Count -eq 0) { throw 'The blocklist is empty.' }
    $rules = @(
        foreach ($domain in $domains) {
            "MAP $domain ~NOTFOUND"
            "MAP *.$domain ~NOTFOUND"
        }
    ) -join ', '
    $arguments = '--host-resolver-rules="' + $rules + '" --disable-http-cache'
    if ($arguments.Length + $BlitzPath.Length -gt 30000) {
        throw 'The blocklist exceeds the Windows command-line limit. Shorten it.'
    }
    [pscustomobject]@{ Domains = $domains; Arguments = $arguments }
}

# Dot-source this file to use the rule builder in verification scripts.
if ($MyInvocation.InvocationName -eq '.') { return }

try {
    if (-not (Test-Path -LiteralPath $BlitzPath -PathType Leaf)) {
        throw "Blitz executable not found: $BlitzPath"
    }
    $configuration = Get-BlockRules (Join-Path $PSScriptRoot 'blocked-domains.txt')
    if (-not $NoCosmetics) {
        foreach ($file in @('Cdp.ps1','cosmetic-filter.js','Watch-BlitzCosmetics.ps1')) {
            if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $file))) { throw "Missing cosmetic filter file: $file" }
        }
    }
    if ($Check) {
        Write-Host "OK: Blitz found. $($configuration.Domains.Count) domains and their subdomains configured."
        Write-Host "Cosmetic filtering enabled: $(-not $NoCosmetics)"
        Write-Host 'This checks configuration only; it does not verify live ad blocking.'
        return
    }

    # Electron's single-instance handling would discard the new network flags.
    if (@(Get-Process -Name Blitz -ErrorAction SilentlyContinue).Count -gt 0) {
        throw 'Blitz is already running. Quit Blitz from its system-tray menu, then run this launcher again. Closing its window may leave it running. Your current session has not been interrupted.'
    }

    $launchArguments = $configuration.Arguments
    if (-not $NoCosmetics) {
        $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
        try {
            $listener.Start()
            $port = $listener.LocalEndpoint.Port
        } finally { $listener.Stop() }
        $launchArguments += " --remote-debugging-address=127.0.0.1 --remote-debugging-port=$port"
    }
    $blitzProcess = Start-Process -FilePath $BlitzPath -ArgumentList $launchArguments -WorkingDirectory (Split-Path -Parent $BlitzPath) -PassThru
    if (-not $NoCosmetics) {
        $helper = Join-Path $PSScriptRoot 'Watch-BlitzCosmetics.ps1'
        $helperArguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "' + $helper + '" -Port ' + $port + ' -BlitzProcessId ' + $blitzProcess.Id
        Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $helperArguments -WindowStyle Hidden
    }
    Write-Host "Blitz launched with $($configuration.Domains.Count) blocked ad domains."
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
