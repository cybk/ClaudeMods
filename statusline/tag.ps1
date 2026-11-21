# tag.ps1 - create/show/remove the .claude-tag of the current folder.
#   tag api        -> writes "api" to .\.claude-tag
#   tag            -> shows the tag in effect for this folder
#   tag -Remove    -> deletes .\.claude-tag
param(
    [Parameter(Position = 0)][string]$Name,
    [switch]$Remove
)

$file = Join-Path (Get-Location).Path '.claude-tag'

if ($Remove) {
    if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file; "Removed $file" }
    else { "No .claude-tag in this folder." }
    return
}

if ([string]::IsNullOrWhiteSpace($Name)) {
    if ($env:CLAUDE_TAG) { "CLAUDE_TAG=$($env:CLAUDE_TAG) (environment variable, overrides the file)" }
    $d = (Get-Location).Path
    while ($d) {
        $f = Join-Path $d '.claude-tag'
        if (Test-Path -LiteralPath $f -PathType Leaf) { "$((Get-Content -LiteralPath $f -TotalCount 1).Trim())  <- $f"; return }
        if (Test-Path -LiteralPath (Join-Path $d '.git')) { break }
        $p = Split-Path $d -Parent
        if (-not $p -or $p -eq $d) { break }
        $d = $p
    }
    "No tag set; the folder name is used: $(Split-Path (Get-Location).Path -Leaf)"
    return
}

$Name = ($Name -split "[\r\n]")[0].Trim()
[IO.File]::WriteAllText($file, "$Name`n", [Text.UTF8Encoding]::new($false))   # UTF-8 without BOM
"Tag '$Name' -> $file"
