<#
  .DESCRIPTION

  Setup local environment for running tests and starting app function.

  .EXAMPLE
  PS> .\Build\Templates\Scripts\Setup\setupGitHooks.ps1

  #>
Import-Module "$PSScriptRoot\..\HelpModule\findProjectToBump.psm1" -Force

  if(git rev-parse --abbrev-ref HEAD -ne "master")
  {
    Write-Host "Hook called" -ForegroundColor Cyan

    $filesName = @("*\*ReleaseNotes.md")
    $files = Get-ChildItem -Path $filesName -Recurse | Select-Object -ExpandProperty FullName

    foreach ($file in $files)
    {
      Write-Host "files to tjek: $file" -ForegroundColor Cyan
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
      Write-Host "files edited: $test"

      Write-Host "file: $file" -ForegroundColor Cyan

      $ReleaseNotesConfig = ConvertFrom-Json -InputObject (Get-Content "$file.json" -Raw)

      if($ReleaseNotesConfig.VersionBump -eq 0 -and $codeUpdated){
        Write-Host "There are Code Update in this project"
        $ReleaseNotesConfig.VersionBump = 1
        $ReleaseNotesConfig.ReleaseText = "- Don't know what have changes"
      } elseif ($ReleaseNotesConfig.VersionBump -eq 0 -and $projecFilsUpdated){
        Write-Host "There are project fils updated in this project"
        $ReleaseNotesConfig.VersionBump = 3
        $ReleaseNotesConfig.ReleaseText = "- Dependencies updated."
      } elseif ($ReleaseNotesConfig.VersionBump -eq 0 -and $detectedBuildFilesEdited ){
        Write-Host "There are detected Build Files Edited in this project"
        $ReleaseNotesConfig.VersionBump = 3
        $ReleaseNotesConfig.ReleaseText = "- No functional changes."
      }

      if($ReleaseNotesConfig.VersionBump -ne 0)
      {
        $isBuildFilesEdited = DetectBuildFiles -$filesUpdated
        write-Host "is edited: $isBuildFilesEdited"
        Write-Host ("Version To bump: " + $ReleaseNotesConfig.VersionBump) -ForegroundColor Cyan

        $ReleaseNotes = Get-Content $file -Raw
        $match = [Regex]::Match($ReleaseNotes, '## Version (?<Major>[\d]+)\.(?<Minor>[\d]+)\.(?<Patch>[\d]+)')
        $Major = [int]::Parse($match.Groups["Major"].Value)
        $Minor = [int]::Parse($match.Groups["Minor"].Value)
        $Patch = [int]::Parse($match.Groups["Patch"].Value)
        if($ReleaseNotesConfig.VersionBump -eq 1){
          $Major++
          $Minor = 0
          $Patch = 0
        }
        elseif($ReleaseNotesConfig.VersionBump -eq 2){
          $Minor++
          $Patch = 0
        }
        elseif($ReleaseNotesConfig.VersionBump -eq 3){
          $Patch++
        }

        #ReleaseNotes update
        $newText = "## Version $Major.$Minor.$Patch`n" + $ReleaseNotesConfig.ReleaseText + "`n`n* * *`n" + $match.Value
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
    }
  }
