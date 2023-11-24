<#
  .DESCRIPTION

  Setup local environment for running tests and starting app function.

  .EXAMPLE
  PS> .\Build\Templates\Scripts\Setup\setupGitHooks.ps1

  #>
Import-Module "$PSScriptRoot\..\HelpModule\findProjectToBump.psm1" -Force

$branchName = git rev-parse --abbrev-ref HEAD

if($branchName -eq "master") # brek if is master
{
  Write-Host "We are on master" -ForegroundColor Cyan
  return
}
try {
  dotnet restore --force-evaluate
}
catch { }

Write-Host "Hook called" -ForegroundColor Cyan

$files = Get-ChildItem -Path "*ReleaseNotes.md" -Recurse | Select-Object -ExpandProperty FullName

UpdaetJsonReleaseNotesConfig -ReleaseNotesFiles $files -branchName $branchName

foreach ($file in $files)
{
  Write-Host "check files: $file" -ForegroundColor Cyan
  git checkout origin/master $file
  git add $file
}

$filesUpdated = filsUpdated
$detectedBuildFilesEdited = DetectBuildFiles -$filesUpdated

Write-Host "files edited: $detectedBuildFilesEdited"

foreach ($file in $files)
{
  if(-not (Test-Path -Path "$file.json"))
  {
    continue
  }

  $projecFilsUpdated = DetectUpdatedProjectConfigFiles -readmefilePath $file -editedFiles $filesUpdated
  $codeUpdated = DetectUpdatedProjectFiles -readmefilePath $file -editedFiles $filesUpdated

  Write-Host "File: $file" -ForegroundColor Cyan

  $ReleaseNotesConfig = ConvertFrom-Json -InputObject (Get-Content "$file.json" -Raw)
  if($ReleaseNotesConfig.VersionBump -eq 0 -and $codeUpdated)
  {
    Write-Host "Code Updated in this project" -ForegroundColor Cyan
    continue
  }

  if ($ReleaseNotesConfig.VersionBump -eq 0 -and $projecFilsUpdated)
  {
    Write-Host "Project Files Updated in this project" -ForegroundColor Cyan
    $ReleaseNotesConfig.VersionBump = 3
    $ReleaseNotesConfig.ReleaseText = @("Dependencies updated.")
  } elseif ($ReleaseNotesConfig.VersionBump -eq 0 -and $detectedBuildFilesEdited )
  {
    Write-Host "Detected Build Files Edited in this project" -ForegroundColor Cyan
    $ReleaseNotesConfig.VersionBump = 3
    $ReleaseNotesConfig.ReleaseText = @("No functional changes.")
  } elseif ($ReleaseNotesConfig.VersionBump -eq 0)
  {
    Write-Host "No update for the project" -ForegroundColor Cyan
    continue
  }

  $isBuildFilesEdited = DetectBuildFiles -$filesUpdated
  write-Host "is edited: $isBuildFilesEdited"
  Write-Host ("Version To bump: " + $ReleaseNotesConfig.VersionBump) -ForegroundColor Cyan

  $ReleaseNotes = Get-Content $file -Raw
  $match = [Regex]::Match($ReleaseNotes, '## Version (?<Major>[\d]+)\.(?<Minor>[\d]+)\.(?<Patch>[\d]+)')
  $Major = [int]::Parse($match.Groups["Major"].Value)
  $Minor = [int]::Parse($match.Groups["Minor"].Value)
  $Patch = [int]::Parse($match.Groups["Patch"].Value)

  #ReleaseNotes update
  $releaseText = ""
  foreach ($text in $ReleaseNotesConfig.ReleaseText)
  {
    $releaseText += "- $text`n"
  }

  if($ReleaseNotesConfig.VersionBump -eq 1){
    $Major++
    $Minor = 0
    $Patch = 0
    $releaseText += "`n"
    $releaseText = $releaseText.Replace("- `n`n","")
    $releaseText += '<span style="background-color: #ffdacc; color: black;">**Breaking changes:**</span>' + "`n" 
    foreach ($text in $ReleaseNotesConfig.BreakingText)
    {
      $releaseText += "- $text`n"
    }
  }
  elseif($ReleaseNotesConfig.VersionBump -eq 2){
    $Minor++
    $Patch = 0
  }
  elseif($ReleaseNotesConfig.VersionBump -eq 3){
    $Patch++
  }

  $newText = "## Version $Major.$Minor.$Patch`n" + $releaseText + "`n* * *`n" + $match.Value
  $ReleaseNotes = $ReleaseNotes -replace $match.Value, $newText

  Set-Content $file $ReleaseNotes -Force -NoNewline -Encoding Ascii
  git add $file

  #csproj update
  $replacement = "$Major.$Minor.$Patch" + '$(VersionSuffix)'

  $pagetesId = (Get-Content -Path $file -TotalCount 1)

  $pattern = "<PackageId>" + ([regex]::Match($pagetesId, "Energinet.*?(?= )")) + "</PackageId>"
  Write-Host ("Project File Pattern: " + $pattern) -ForegroundColor Cyan
  $projecFile = Get-ChildItem -Path ".\" -Recurse -Include *.csproj | Select-String -Pattern "$pattern" | Select-Object Path
  Write-Host ("Project File: " + $projecFile.Path) -ForegroundColor Cyan
  [regex]::Replace((Get-Content $projecFile.Path -Raw),'(?<=<PackageVersion>).*?(?=<\/PackageVersion>)', $replacement) | Set-Content $projecFile.Path -NoNewline -Encoding Ascii
  git add $projecFile.Path

}
