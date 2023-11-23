<#
  .DESCRIPTION

  Setup local environment for running tests and starting app function.

  .EXAMPLE
  PS> .\Build\Templates\Scripts\Setup\setupGitHooks.ps1

  #>
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

    foreach ($file in $files)
    {
      if(-not (Test-Path -Path "$file.json"))
      {
        continue
      }

      Write-Host "File: $file" -ForegroundColor Cyan

      $ReleaseNotesConfig = ConvertFrom-Json -InputObject (Get-Content "$file.json" -Raw)

      if($ReleaseNotesConfig.VersionBump -ne 0)
      {
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

        #ReleaseNotes Opdate
        $newText = "## Version $Major.$Minor.$Patch`n" + $ReleaseNotesConfig.ReleaseText + "`n`n* * *`n" + $match.Value
        $ReleaseNotes = $ReleaseNotes -replace $match.Value, $newText
        Set-Content $file $ReleaseNotes -Force -NoNewline -Encoding Ascii
        git add $file

        #csproj Opdate
        $replacement = "$Major.$Minor.$Patch" + '$(VersionSuffix)'

        $pagetesId = (Get-Content -Path $file -TotalCount 1)

        $pattern = "<PackageId>" + ([regex]::Match($pagetesId, "Energinet.*?(?= )")) + "</PackageId>"
        Write-Host ("Project File Patton: " + $pattern) -ForegroundColor Cyan
        $projecFile = Get-ChildItem -Path ".\" -Recurse -Include *.csproj | Select-String -Pattern "$pattern" | Select-Object Path
        Write-Host ("Project File: " + $projecFile.Path) -ForegroundColor Cyan
        [regex]::Replace((Get-Content $projecFile.Path -Raw),'(?<=<PackageVersion>).*?(?=<\/PackageVersion>)', $replacement) | Set-Content $projecFile.Path -NoNewline -Encoding Ascii
        git add $projecFile.Path
      }
    }
  }
