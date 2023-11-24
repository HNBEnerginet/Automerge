<#
  .DESCRIPTION

  Setup local environment for running tests and starting app function.

  .EXAMPLE
  PS> .\Build\Templates\Scripts\Setup\setupGitHooks.ps1

  #>
Import-Module "$PSScriptRoot\..\HelpModule\findProjectToBump.psm1" -Force

$mypath = $MyInvocation.MyCommand.Path
Write-Output "Path of the script : $mypath"
$path = Split-Path $mypath -Parent
$path = $path -replace "\\", "/"
Write-Output "Path of the Parent : $path"
$gitHookUri = ".git\hooks\"
$gitAddributFile = ".git\info\attributes"
$refGitHooksFolder = "$path/../GitHooks"

if (-not(Test-Path $gitHookUri))
{
    Write-Output "Git hook folder not found" -ForegroundColor Cyan
    return
}

if (-not(Test-Path $refGitHooksFolder))
{
    Write-Output "Git hook PS folder not found" -ForegroundColor Cyan
    return
}

$gitBranchName = $branchName = git rev-parse --abbrev-ref HEAD
$files = Get-ChildItem -Path "*ReleaseNotes.md" -Recurse | Select-Object -ExpandProperty FullName

UpdateJsonReleaseNotesConfig -ReleaseNotesFiles $files -branchName $gitBranchName

Write-Output "Start Creation of git hook post-merge file" -ForegroundColor Cyan
$gitHooks = Get-ChildItem -Path $refGitHooksFolder -File -Name

foreach ($gitHook in $gitHooks)
{

    $gitHookPostMergeFileUri = $gitHookUri + ($gitHook -replace ".ps1", "")
    Write-Output "Creating git hook post-merge file $gitHookPostMergeFileUri" -ForegroundColor Cyan
    $fileContent = "#!/bin/sh`n"
    $fileContent += "C:\\windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe -File $refGitHooksFolder/$gitHook"
    Set-Content $gitHookPostMergeFileUri $fileContent -Force
    # Allow execution
    Write-Output "Setting execution policy on git hook post-merge file" -ForegroundColor Cyan
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}

git config merge.ours.driver true

$attributesContent = @'
**/ReleaseNotes/*ReleaseNotes.md merge=ours
**/ReleaseNotes/*ReleaseNotes.md.json merge=ours
**/packages.lock.json merge=ours
'@
Set-Content $gitAddributFile $attributesContent -Force
