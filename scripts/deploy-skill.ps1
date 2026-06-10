# 把仓库中的 skill 部署到 Claude Code 全局 skills 目录。
# 仓库 skills/ 是唯一事实来源;安装目录只是部署产物,不要直接改它。
$ErrorActionPreference = "Stop"

$repoSkills = Join-Path $PSScriptRoot "..\skills"
$dstRoot = Join-Path $env:USERPROFILE ".claude\skills"

Get-ChildItem -Directory $repoSkills | ForEach-Object {
    $dst = Join-Path $dstRoot $_.Name
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
    Copy-Item -Recurse -Force $_.FullName $dst
    Write-Host "Deployed $($_.Name) -> $dst"
}
