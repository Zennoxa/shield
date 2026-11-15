# Zennoxa Shield CLI installer for Windows (Windows PowerShell 5.1 or PowerShell 7).
#
#   irm https://raw.githubusercontent.com/Zennoxa/shield/main/install.ps1 | iex
#
# Downloads shield-windows-amd64.exe from the release, checks it against the
# release's SHA256SUMS, installs it as shield.exe under
# %LOCALAPPDATA%\Programs\shield, adds that folder to your user PATH and runs
# `shield version`. No administrator rights are needed. Nothing else is
# installed and nothing is sent anywhere.
#
# Options (environment variables):
#   $env:SHIELD_VERSION      release tag to install, for example v0.7.0 (default: latest)
#   $env:SHIELD_INSTALL_DIR  folder to install into

& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'   # the progress bar makes downloads very slow in 5.1
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch { }

    $repo = 'Zennoxa/shield'
    $asset = 'shield-windows-amd64.exe'   # also runs on Windows on ARM through the built-in x64 emulation

    $version = 'latest'
    if ($env:SHIELD_VERSION) { $version = $env:SHIELD_VERSION }
    if ($version -eq 'latest') {
        $base = "https://github.com/$repo/releases/latest/download"
    } elseif ($version -match '^v[0-9][0-9A-Za-z.+-]*$') {
        $base = "https://github.com/$repo/releases/download/$version"
    } else {
        throw "SHIELD_VERSION must be a release tag such as v0.7.0, or latest"
    }

    if ($env:SHIELD_INSTALL_DIR) {
        $dir = $env:SHIELD_INSTALL_DIR
    } elseif ($env:LOCALAPPDATA) {
        $dir = Join-Path $env:LOCALAPPDATA 'Programs\shield'
    } else {
        throw "LOCALAPPDATA is not set; set SHIELD_INSTALL_DIR to the folder to install into"
    }

    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('shield-install-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    try {
        $download = Join-Path $tmp $asset
        $sums = Join-Path $tmp 'SHA256SUMS'
        Write-Host "Downloading $asset ($version)"
        Invoke-WebRequest -UseBasicParsing -Uri "$base/$asset" -OutFile $download
        Invoke-WebRequest -UseBasicParsing -Uri "$base/SHA256SUMS" -OutFile $sums

        # The checksum is never skipped.
        $want = $null
        foreach ($line in Get-Content -LiteralPath $sums) {
            $parts = $line.Trim() -split '\s+', 2
            if ($parts.Count -eq 2 -and $parts[1].TrimStart('*') -eq $asset) { $want = $parts[0].ToLowerInvariant() }
        }
        if (-not $want) { throw "SHA256SUMS of this release does not list $asset" }
        $got = (Get-FileHash -Algorithm SHA256 -LiteralPath $download).Hash.ToLowerInvariant()
        if ($want -ne $got) { throw "checksum mismatch for ${asset}: expected $want, got $got" }
        Write-Host 'Checksum verified.'

        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $target = Join-Path $dir 'shield.exe'
        Copy-Item -Force -LiteralPath $download -Destination $target
    } finally {
        Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
    }

    # A file saved by a browser carries a "downloaded from the internet" mark
    # that makes Windows ask before running it; one saved here does not.
    # Clearing the mark is harmless either way.
    try { Unblock-File -LiteralPath $target } catch { }

    # Put the folder on the user PATH (new terminals) and on this session's PATH.
    $addedToPath = $false
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @()
    if ($userPath) { $entries = @($userPath -split ';' | Where-Object { $_ }) }
    if ($entries -notcontains $dir) {
        [Environment]::SetEnvironmentVariable('Path', (($entries + $dir) -join ';'), 'User')
        $addedToPath = $true
    }
    if (@($env:Path -split [IO.Path]::PathSeparator) -notcontains $dir) {
        $env:Path = $env:Path + [IO.Path]::PathSeparator + $dir
    }

    # Prove it runs.
    $installed = & $target version 2>&1
    if ($LASTEXITCODE -ne 0) { throw "$target was installed but does not run: $installed" }

    Write-Host ''
    Write-Host "Installed $installed"
    Write-Host "  at $target"
    if ($addedToPath) {
        Write-Host "  $dir was added to your user PATH. Terminals that are already open need to be reopened."
    }
    Write-Host ''
    Write-Host 'Try it:  shield scan .'
}
