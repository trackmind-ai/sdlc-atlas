# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
#
# Windows equivalent of the Makefile. Keep the two in step: every target here should exist
# there under the same name, and do the same thing.
#
#   .\tasks.ps1 check      # run before opening a PR
#   .\tasks.ps1 help

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('help', 'install', 'load', 'check', 'validate', 'lint', 'test', 'clean')]
    [string]$Task = 'help'
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Plugin = Join-Path $Root 'plugins/sdlc-atlas'

function Resolve-Python {
    foreach ($c in @('python', 'py', 'python3')) {
        $exe = Get-Command $c -ErrorAction SilentlyContinue
        # `python3` on Windows is often a WindowsApps stub that exits without running,
        # so confirm the interpreter actually executes before returning it.
        if ($exe -and (& $c -c 'print(1)' 2>$null)) { return $c }
    }
    throw 'No working Python interpreter found (need 3.9+ for scripts/validate_agents.py).'
}

function Invoke-Help {
    @'
sdlc-atlas — development commands

  .\tasks.ps1 install     Install the platform into ~/.claude/ (no plugin manager)
  .\tasks.ps1 load        Print the commands to register this checkout as a local plugin

  .\tasks.ps1 check       validate + lint + package self-test (run before a PR)
  .\tasks.ps1 validate    Plugin manifests + agent frontmatter and skill references
  .\tasks.ps1 lint        shellcheck every shell script
  .\tasks.ps1 test        Package self-test (tools/verify-package.sh)

  .\tasks.ps1 clean       Remove caches and converter output
'@ | Write-Host
}

function Invoke-Install {
    bash (Join-Path $Plugin 'install.sh') --platform
    if ($LASTEXITCODE -ne 0) { throw "install.sh failed with exit code $LASTEXITCODE" }
}

function Invoke-Load {
    # The dev marketplace is named `trackmind-sdlc-atlas-dev`, never `trackmind`, so adding
    # it cannot replace the published trackmind-ai/marketplace catalog.
    Write-Host 'Run these inside Claude Code:'
    Write-Host "  /plugin marketplace add $Root"
    Write-Host '  /plugin install sdlc-atlas@trackmind-sdlc-atlas-dev'
}

function Invoke-Validate {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        claude plugin validate $Root
        if ($LASTEXITCODE -ne 0) { throw 'claude plugin validate failed' }
    }
    else {
        Write-Host '! claude CLI not found — skipping manifest validation (CI runs it)'
    }

    $py = Resolve-Python
    & $py (Join-Path $Root 'scripts/validate_agents.py')
    if ($LASTEXITCODE -ne 0) { throw 'validate_agents.py failed' }
}

function Invoke-Lint {
    if (-not (Get-Command shellcheck -ErrorAction SilentlyContinue)) {
        Write-Host '! shellcheck not found — install it or rely on CI'
        return
    }
    $scripts = Get-ChildItem -Path $Root -Filter *.sh -Recurse -File |
        Where-Object { $_.FullName -notmatch '\\\.git\\' } |
        ForEach-Object { $_.FullName }
    if (-not $scripts) { Write-Host 'no shell scripts found'; return }
    shellcheck --severity=warning @scripts
    if ($LASTEXITCODE -ne 0) { throw 'shellcheck reported findings' }
    Write-Host 'shellcheck clean'
}

function Invoke-Test {
    Push-Location $Plugin
    try {
        bash tools/verify-package.sh
        if ($LASTEXITCODE -ne 0) { throw 'package self-test failed' }
    }
    finally { Pop-Location }
}

function Invoke-Check {
    Invoke-Validate
    Invoke-Lint
    Invoke-Test
    Write-Host 'all checks passed' -ForegroundColor Green
}

function Invoke-Clean {
    Get-ChildItem -Path $Root -Directory -Recurse -Filter __pycache__ -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $Root -File -Recurse -Filter *.pyc -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $Plugin 'projects/project-template-cursor') -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path (Join-Path $Plugin 'projects') -Directory -Filter 'tmp-write-*' -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host 'clean'
}

switch ($Task) {
    'help' { Invoke-Help }
    'install' { Invoke-Install }
    'load' { Invoke-Load }
    'check' { Invoke-Check }
    'validate' { Invoke-Validate }
    'lint' { Invoke-Lint }
    'test' { Invoke-Test }
    'clean' { Invoke-Clean }
}
