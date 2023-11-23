<#
  .DESCRIPTION

  Setup local environment for running tests and starting app function.

  .EXAMPLE
  PS> .\Build\Templates\Scripts\Setup\setupGitHooks.ps1

  #>

$branchName = git rev-parse --abbrev-ref HEAD
$files = Get-ChildItem -Path "*ReleaseNotes.md" -Recurse | Select-Object -ExpandProperty FullName

foreach ($file in $files)
{
    if (Test-Path -Path "$file.json")
    {
        write-host "could find file $file"
        $ReleaseNotesConfig = ConvertFrom-Json -InputObject (Get-Content "$file.json" -Raw)
        if($ReleaseNotesConfig.BranchName -eq $branchName)
        {
            write-host "skip file because of branch $branchName"
          continue
        }
    }

    $content = @{
        BranchName = $branchName
        VersionBump = 0
        ReleaseText = ""
    }
    Set-Content "$file.json" (ConvertTo-Json $content) -Force -NoNewline -Encoding Ascii
}
