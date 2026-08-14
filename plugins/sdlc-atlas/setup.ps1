# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
<# sdlc-atlas one-shot setup for Windows.
   Run from the extracted package folder, e.g.:
     .\setup.ps1 -Project "C:\dev\todo-api" -Stack "django,angular" -Layer todo
     .\setup.ps1 -Project "C:\dev\acme-api" -Stack fastapi -Layer acme
     .\setup.ps1 -Project "C:\dev\myrepo" -Stack django -Org "C:\dev\org-policy"
   If PowerShell blocks scripts:  powershell -ExecutionPolicy Bypass -File .\setup.ps1 ...
#>
param(
  [Parameter(Mandatory=$true)][string]$Project,
  [string]$Stack = "django",
  [string]$Org = "",
  [string]$Layer = "",
  [ValidateSet("minimal", "standard", "enterprise")]
  [string]$Profile = "standard",
)
$ErrorActionPreference = "Stop"
# Locate bash.exe (Git for Windows - required by Claude Code anyway)
$cands = @("$env:ProgramFiles\Git\bin\bash.exe",
           "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
           "$env:LocalAppData\Programs\Git\bin\bash.exe")
$bash = $cands | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $bash) { $bash = (Get-Command bash -ErrorAction SilentlyContinue).Source }
if (-not $bash) { Write-Error "Git Bash not found. Install Git for Windows (required by Claude Code), then re-run."; exit 1 }
function ToBashPath([string]$p) {
  $full = [System.IO.Path]::GetFullPath($p)
  "/" + $full.Substring(0,1).ToLower() + $full.Substring(2).Replace("\","/")
}
$src   = ToBashPath $PSScriptRoot
$projB = ToBashPath $Project
$args_ = @("$src/setup-all.sh", "--project", $projB, "--stack", $Stack, "--profile", $Profile)
if ($Org)   { $args_ += @("--org", (ToBashPath $Org)) }
if ($Layer) { $args_ += @("--layer", $Layer) }
Write-Host "Using bash: $bash"
& $bash @args_
if ($LASTEXITCODE -eq 0) {
  Write-Host ""
  Write-Host "Layers installed:" -ForegroundColor Green
  Write-Host "  L0 Platform -> $env:USERPROFILE\.claude"
  Write-Host "  L1 Stack    -> merged into $Project\.claude"
  if ($Org) { Write-Host "  L2 Org      -> merged from $Org (set org_policy: in CLAUDE.md)" }
  if ($Layer) { Write-Host "  L3 Project  -> projects/$Layer -> $Project\.claude" }
  else { Write-Host "  L3 Project  -> $Project\.claude (from template)" }
}
exit $LASTEXITCODE
