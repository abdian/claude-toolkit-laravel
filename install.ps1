<#
  Claude Code toolkit installer — Windows / PowerShell

  Usage:  .\install.ps1                  -> starter 6, into THIS project
          .\install.ps1 -All             -> all 17, into THIS project
          .\install.ps1 -All -Global     -> all 17, into ~\.claude\skills
          .\install.ps1 -All -Copy       -> real copies instead of symlinks
          .\install.ps1 -All -Force      -> overwrite what's already there

  Default is PROJECT scope + SYMLINK:
    skills land in <toolkit-parent>\.claude\skills\, applying to this project
    only. Real symlinks on Windows need Developer Mode (or an elevated shell);
    without it, real copies are installed and you re-run with -Force after
    editing a skill. The script tells you which one you got.

  NOTE: a personal skill (~\.claude\skills\) OVERRIDES a project skill of the
  same name. If you installed globally before, use -Global or you will keep
  running the old copy.
#>
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Global,
    [switch]$Project,
    [switch]$Copy,
    [switch]$Link,
    [switch]$Force,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

if ($Help) {
    Get-Content $PSCommandPath | Select-Object -Skip 1 -First 18
    exit 0
}

$Here = Split-Path -Parent $PSCommandPath
$Src  = Join-Path $Here 'skills'
$Root = Split-Path -Parent $Here     # the project dir holding this toolkit

$Starter = @('start','next','brief','plan-check','fix-one','lazy')
$Rest    = @('edges','debt','spec-import','explain','ctx-audit','ctx-interview',
             'ctx-generate','ctx-verify','ctx-learn','audit-codebase',
             'find-overengineering')

if ($All) { $Set = $Starter + $Rest } else { $Set = $Starter }

# -Project and -Copy win over their opposites when both are passed.
$Scope = 'project'
if ($Global)  { $Scope = 'global' }
if ($Project) { $Scope = 'project' }

$Mode = 'link'
if ($Link) { $Mode = 'link' }
if ($Copy) { $Mode = 'copy' }

if ($Scope -eq 'global') {
    $Dest = Join-Path $HOME '.claude\skills'
} else {
    $Dest = Join-Path $Root '.claude\skills'
}

# Probe for real symlink support rather than trusting it: without Developer
# Mode, New-Item -ItemType SymbolicLink throws for a non-elevated user.
if ($Mode -eq 'link') {
    $probeDir  = Join-Path ([System.IO.Path]::GetTempPath()) ("ct-probe-" + [guid]::NewGuid().ToString('N'))
    $probeLink = Join-Path $probeDir 'probe'
    New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
    $linkOk = $false
    try {
        New-Item -ItemType SymbolicLink -Path $probeLink -Target $Src -ErrorAction Stop | Out-Null
        $linkOk = $true
    } catch {
        $linkOk = $false
    }
    Remove-Item -Recurse -Force $probeDir -ErrorAction SilentlyContinue
    if (-not $linkOk) {
        Write-Host "  ! real symlinks unavailable here - installing real copies instead."
        Write-Host "    edits in $Src\ will NOT propagate; re-run with -Force after"
        Write-Host "    changing a skill. (Turn on Settings > Privacy & security >"
        Write-Host "    For developers > Developer Mode to get real symlinks.)"
        Write-Host ""
        $Mode = 'copy'
    }
}

New-Item -ItemType Directory -Path $Dest -Force | Out-Null
Write-Host "-> scope : $Scope"
Write-Host "-> dest  : $Dest"
if ($Force) { Write-Host "-> mode  : $Mode (overwriting)" } else { Write-Host "-> mode  : $Mode" }
Write-Host ""

$installed = 0
$skipped   = 0

foreach ($s in $Set) {
    $srcSkill = Join-Path $Src $s
    $dstSkill = Join-Path $Dest $s

    if (-not (Test-Path (Join-Path $srcSkill 'SKILL.md'))) {
        Write-Host "  x $s  - not found in $Src, skipping"
        continue
    }

    if (Test-Path $dstSkill) {
        if ($Force) {
            Remove-Item -Recurse -Force $dstSkill
        } else {
            Write-Host "  . $s  - already there, left alone (use -Force to update)"
            $skipped++
            continue
        }
    }

    if ($Mode -eq 'link') {
        New-Item -ItemType SymbolicLink -Path $dstSkill -Target $srcSkill | Out-Null
        Write-Host "  + $s  (symlink)"
    } else {
        Copy-Item -Recurse $srcSkill $dstSkill
        Write-Host "  + $s"
    }
    $installed++
}

Write-Host ""
Write-Host "done. installed: $installed - left alone: $skipped"
if ($skipped -gt 0) {
    Write-Host "      re-run with -Force to refresh the ones left alone."
}
Write-Host ""

if ($Scope -eq 'project') {
    Write-Host "next:"
    Write-Host "  1. run 'claude' from:  $Root"
    Write-Host "     (project skills load from the directory you start in, and from"
    Write-Host "      .claude\skills below it - not from directories above it)"
    Write-Host "  2. type: /skills   to confirm they loaded"
    Write-Host ""
    Write-Host "  commit .claude\skills\ if you want teammates to get them too."
} else {
    Write-Host "next:  restart Claude Code once, then run 'claude' anywhere and type /skills"
}
