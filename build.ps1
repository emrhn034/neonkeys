$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework/v4.0.30319/csc.exe'
}
if (-not (Test-Path -LiteralPath $compiler)) {
    throw '.NET Framework C# compiler was not found. Build on Windows with .NET Framework 4.x installed.'
}
Push-Location -LiteralPath $PSScriptRoot
try {
    New-Item -ItemType Directory -Path dist -Force | Out-Null
    & $compiler /nologo /target:winexe /optimize+ /reference:System.Windows.Forms.dll /reference:System.Drawing.dll /resource:panel.html,NeonKeys.panel.html /resource:overlay.html,NeonKeys.overlay.html /out:dist/NeonKeys.exe NeonKeys.cs
    if ($LASTEXITCODE -ne 0) { throw 'C# compilation failed.' }
    Copy-Item -LiteralPath BENI-OKU.txt, LICENSE -Destination dist -Force
    Compress-Archive -LiteralPath dist/NeonKeys.exe, dist/BENI-OKU.txt, dist/LICENSE -DestinationPath dist/NeonKeys.zip -Force
    $checksums = foreach ($file in 'NeonKeys.exe', 'NeonKeys.zip') {
        $hash = (Get-FileHash -LiteralPath (Join-Path dist $file) -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $file"
    }
    $checksums | Set-Content -LiteralPath dist/SHA256SUMS.txt -Encoding ascii
    Write-Output 'Built dist/NeonKeys.exe, dist/NeonKeys.zip, and dist/SHA256SUMS.txt'
} finally { Pop-Location }
