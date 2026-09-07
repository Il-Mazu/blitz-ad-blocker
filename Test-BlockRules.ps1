$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Start-Blitz-AdBlock.ps1"
$config = Get-BlockRules "$PSScriptRoot\blocked-domains.txt"
if (-not $config.Arguments.Contains('MAP doubleclick.net ~NOTFOUND, MAP *.doubleclick.net ~NOTFOUND')) {
    throw 'Missing root/subdomain rules.'
}
$fixture = Join-Path $PSScriptRoot 'test-domains.tmp'
try {
    @('# comment', 'EXAMPLE.COM', 'example.com # duplicate') | Set-Content $fixture
    $result = Get-BlockRules $fixture
    if ($result.Domains.Count -ne 1) { throw 'Deduplication failed.' }
    foreach ($bad in @('blitz.gg', 'auth.blitz.gg', 'riotgames.com', 'https://example.com/ad', 'example.com, MAP * 127.0.0.1', '*.example.com')) {
        Set-Content $fixture $bad
        $rejected = $false
        try { $null = Get-BlockRules $fixture } catch { $rejected = $true }
        if (-not $rejected) { throw "Invalid/protected entry accepted: $bad" }
    }
    Write-Host 'PASS: root/subdomain rules, normalization, deduplication, input validation, protected domains.'
} finally {
    Remove-Item -LiteralPath $fixture -ErrorAction SilentlyContinue
}
