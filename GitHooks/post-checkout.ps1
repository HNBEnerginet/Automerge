<#
  .DESCRIPTION

  Setup local environment for running tests and starting app function.

  .EXAMPLE
  PS> .\Build\Templates\Scripts\Setup\setupGitHooks.ps1

  #>

$branchName = git rev-parse --abbrev-ref HEAD

if(-not (git for-each-ref --format="%(upstream:short)" refs/heads/$branchName))
{
    $files = Get-ChildItem -Path "*\ReleaseNotes.md" -Recurse | Select-Object -ExpandProperty FullName | Split-Path -Parent
    foreach ($file in $files)
    {
      $content = @{
        VersionBump = 0
        ReleaseText = ""
      }
      Set-Content "$file\local.settings.json" (ConvertTo-Json $content) -Force -NoNewline -Encoding Ascii
    }
}