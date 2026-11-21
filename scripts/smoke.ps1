param([string]$Executable = (Join-Path $PSScriptRoot '../dist/NeonKeys.exe'))
$ErrorActionPreference = 'Stop'
$Executable = (Resolve-Path -LiteralPath $Executable).Path
$portCheck = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 47831)
try { $portCheck.Start() }
catch { throw 'Port 47831 is occupied. Close NeonKeys before running the smoke check.' }
finally { $portCheck.Stop() }

$isolated = Join-Path ([IO.Path]::GetTempPath()) ('NeonKeys-smoke-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $isolated | Out-Null
$standalone = Join-Path $isolated 'NeonKeys.exe'
Copy-Item -LiteralPath $Executable -Destination $standalone
$app = $null
$response = $null
$reader = $null
try {
    $app = Start-Process -FilePath $standalone -ArgumentList '--no-panel' -WorkingDirectory $isolated -WindowStyle Hidden -PassThru
    $base = 'http://127.0.0.1:47831'
    $panel = $null
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if ($app.HasExited) { throw 'NeonKeys exited before serving its panel.' }
        try { $panel = Invoke-WebRequest -Uri "$base/" -UseBasicParsing -TimeoutSec 1; break }
        catch { Start-Sleep -Milliseconds 100 }
    }
    if ($null -eq $panel -or $panel.Content -notmatch 'data-design="glass"') { throw 'Embedded panel failed.' }
    $overlay = Invoke-WebRequest -Uri "$base/overlay?design=arcade&device=mouse" -UseBasicParsing -TimeoutSec 2
    if ($overlay.Content -notmatch 'design-arcade' -or $overlay.Content -notmatch 'EventSource') { throw 'Embedded overlay failed.' }

    $request = [Net.HttpWebRequest]::Create("$base/events")
    $request.Timeout = 3000
    $request.ReadWriteTimeout = 3000
    $request.Proxy = $null
    $response = $request.GetResponse()
    $reader = [IO.StreamReader]::new($response.GetResponseStream())
    $line = $reader.ReadLine()
    if (-not $line.StartsWith('data: ')) { throw 'No event stream state received.' }
    $state = $line.Substring(6) | ConvertFrom-Json
    if ($null -eq $state.keys -or $state.paused -ne $false) { throw 'Invalid initial event state.' }
    $reader.Dispose(); $reader = $null
    $response.Dispose(); $response = $null

    foreach ($check in @(@{ Path = '/events'; Headers = @{ Origin = 'https://example.com' }; Status = 403 }, @{ Path = '/NeonKeys.cs'; Headers = @{}; Status = 404 })) {
        $status = 0
        try { $result = Invoke-WebRequest -Uri ($base + $check.Path) -Headers $check.Headers -UseBasicParsing -TimeoutSec 2; $status = [int]$result.StatusCode }
        catch { if ($null -ne $_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode } else { throw } }
        if ($status -ne $check.Status) { throw "Unexpected HTTP status $status for $($check.Path)" }
    }
    Write-Output 'PASS: standalone EXE, embedded pages, event stream, origin restriction, and source isolation.'
} finally {
    if ($reader) { $reader.Dispose() }
    if ($response) { $response.Dispose() }
    if ($app -and -not $app.HasExited) { Stop-Process -Id $app.Id; $app.WaitForExit() }
    # Only this uniquely named test directory is removed.
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    $resolved = [IO.Path]::GetFullPath($isolated)
    if ($resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and ([IO.Path]::GetFileName($resolved)).StartsWith('NeonKeys-smoke-')) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
