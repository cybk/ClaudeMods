# claude-tabs.ps1 - open one Windows Terminal tab per project, each titled/colored
# by its tag and running `claude` in its folder with CLAUDE_TAG set.
#
#   .\claude-tabs.ps1                                   # reads ~\.claude\tabs.txt
#   .\claude-tabs.ps1 -File .\tabs.txt
#   .\claude-tabs.ps1 -Tab api=D:\code\api, front=D:\code\web
#   .\claude-tabs.ps1 -DryRun                           # prints the wt command only
#
# tabs file format: one "tag=path" per line; blank lines and lines starting with # are ignored.
param(
    [string]$File = (Join-Path $HOME '.claude\tabs.txt'),
    [string[]]$Tab,
    [switch]$DryRun
)

# Must match the palette and hash in statusline.sh so tab color == status line color.
$palette = 39, 208, 41, 171, 220, 203, 45, 141, 118, 213, 81, 214, 99, 178, 49, 205, 75, 154

function Get-TagColor([string]$tag) {
    [long]$h = 7
    foreach ($c in $tag.ToLowerInvariant().ToCharArray()) { $h = ($h * 31 + [int]$c) % 2147483647 }
    $code = $palette[[int]($h % $palette.Count)]
    # xterm-256 cube (16..231) -> #RRGGBB
    $lv = 0, 95, 135, 175, 215, 255
    $n = $code - 16
    '#{0:X2}{1:X2}{2:X2}' -f $lv[[math]::Floor($n / 36) % 6], $lv[[math]::Floor($n / 6) % 6], $lv[$n % 6]
}

$entries = if ($Tab) { $Tab } elseif (Test-Path -LiteralPath $File) { Get-Content -LiteralPath $File } else {
    Write-Error "No tabs given and $File not found. Use -Tab tag=path or create the file."; return
}

$wtArgs = @()
foreach ($line in $entries) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    $i = $line.IndexOf('=')
    if ($i -lt 1) { Write-Warning "Skipping '$line' (expected tag=path)"; continue }
    $tag = $line.Substring(0, $i).Trim()
    $path = $line.Substring($i + 1).Trim().Trim('"')
    if ($path -eq '~' -or $path.StartsWith('~\') -or $path.StartsWith('~/')) { $path = $HOME + $path.Substring(1) }
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { Write-Warning "Skipping '$tag': folder not found: $path"; continue }

    # EncodedCommand avoids quoting problems and the ';' that wt treats as a command separator.
    $cmd = "`$env:CLAUDE_TAG='$($tag -replace "'","''")'; claude"
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))

    if ($wtArgs.Count) { $wtArgs += ';' }
    $wtArgs += 'new-tab', '--title', $tag, '--suppressApplicationTitle', '--tabColor', (Get-TagColor $tag),
               '-d', $path, 'pwsh', '-NoExit', '-EncodedCommand', $enc
}

if (-not $wtArgs.Count) { Write-Warning 'Nothing to open.'; return }
if ($DryRun) { "wt " + (($wtArgs | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' '); return }
& wt @wtArgs
