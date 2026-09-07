# Minimal synchronous CDP client for Windows PowerShell 5.1.
function Invoke-BlitzCdp {
    param([string]$WebSocketUrl, [string]$Method, [hashtable]$Parameters = @{})
    $uri = [uri]$WebSocketUrl
    if ($uri.Scheme -ne 'ws' -or $uri.Host -ne '127.0.0.1') { throw 'Only loopback CDP connections are allowed.' }
    $socket = New-Object Net.WebSockets.ClientWebSocket
    $socket.Options.Proxy = $null
    $timeout = New-Object Threading.CancellationTokenSource
    $timeout.CancelAfter(5000)
    try {
        $task = $socket.ConnectAsync($uri, $timeout.Token)
        if (-not $task.Wait(5000)) { throw 'CDP connection timed out.' }
        $null = $task.GetAwaiter().GetResult()
        $message = @{id=1; method=$Method; params=$Parameters} | ConvertTo-Json -Depth 20 -Compress
        $bytes = [Text.Encoding]::UTF8.GetBytes($message)
        $task = $socket.SendAsync([ArraySegment[byte]]::new($bytes), [Net.WebSockets.WebSocketMessageType]::Text, $true, $timeout.Token)
        if (-not $task.Wait(5000)) { throw 'CDP send timed out.' }
        $null = $task.GetAwaiter().GetResult()
        do {
            $stream = New-Object IO.MemoryStream
            try {
                do {
                    $buffer = New-Object byte[] 16384
                    $task = $socket.ReceiveAsync([ArraySegment[byte]]::new($buffer), $timeout.Token)
                    if (-not $task.Wait(5000)) { throw 'CDP receive timed out.' }
                    $received = $task.GetAwaiter().GetResult()
                    if ($received.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close) { throw 'Blitz closed the debugging connection.' }
                    $stream.Write($buffer,0,$received.Count)
                    if ($stream.Length -gt 8MB) { throw 'CDP response too large.' }
                } until ($received.EndOfMessage)
                $reply = [Text.Encoding]::UTF8.GetString($stream.ToArray()) | ConvertFrom-Json
            } finally { $stream.Dispose() }
        } until ($reply.PSObject.Properties['id'] -and $reply.id -eq 1)
        if ($reply.PSObject.Properties['error']) { throw ($reply.error | ConvertTo-Json -Compress) }
        return $reply.result
    } finally {
        $socket.Dispose()
        $timeout.Dispose()
    }
}
