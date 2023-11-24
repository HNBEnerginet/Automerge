function filsUpdated
{
    [CmdletBinding()]
    Param()

    Write-Host "Get edited files for branch"
    return git diff --diff-filter=M --name-only master
}

function DetectBuildFiles {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string[]]$editedFiles
    )

    if ($editedFiles.Count -eq 0)
    {
        Write-Host "No edited files in solution for branch"
        return $false
    }
    Write-Host "Edited files:"
    Write-Host "Check project 'Build' for changes"

    foreach ($editedFile in $editedFiles)
    {
        Switch -Wildcard ($editedFile) {
            '*.md' { break; }
            'Build/mend.yml' { break; }
            'Build/repo-analysis.yml' { break; }
            'Build/Templates/jobs-deploy.yml' { break; }
            'Build/Templates/Yml/step-deploy*' { break; }
            'Build/Templates/Yml/jobs-deploy*' { break; }
            'Build/Templates/Yml/stage-deploy*' { break; }
            'Build/Templates/*.bicep' { break; }
            'Build/Templates/Scripts/detectPackagesToPublish.ps1' { break; }
            'Build/Templates/Scripts/Setup/*' { break; }
            'Source/Libraries.sln' { break; }
            'Build/*' {
                Write-Host "File '$editedFile' have changed so we need to publish all packages"
                return $true
            }
        }
    }

    Write-Host "No build files edited"
    return $false
}

function DetectUpdatedProjectFiles
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$readmefilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$editedFiles
    )

    $file_content = Get-Content -Path $readmefilePath -Raw
    $pattern = 'Energinet.DDP.(\S+)'

    $projectNameSpace =""

    if ($file_content -match $pattern) {
        $projectNameSpace = $matches[1]
        Write-Host "Start Evaluating: $projectNameSpace" -ForegroundColor Cyan
    }else{
        write-host "Could not find related project"
        return $false
    }

    foreach ($editedFile in $editedFiles)
    {
        Switch -Wildcard ($editedFile) {
            "*/packages.lock.json" { break; }
            "*.csproj" { break; }
            "*/$projectNameSpace/*" {
               return $true
            }
        }
    }
    return $false;
}

function DetectUpdatedProjectConfigFiles
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$readmefilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$editedFiles
    )

    $file_content = Get-Content -Path $readmefilePath -Raw
    $pattern = 'Energinet.DDP.(\S+)'

    $projectNameSpace =""

    if ($file_content -match $pattern) {
        $projectNameSpace = $matches[1]
        Write-Host "Project name space: $projectNameSpace test"
    }else{
        write-host "Could not find related project"
        return $false
    }

    foreach ($editedFile in $editedFiles)
    {
        if ($editedFile.EndsWith("/Source/$projectNameSpace/packages.lock.json"))
        {
            return $true
        }
    }

    Write-Host "No project files where updated"
    return $false;
}

function UpdaetJsonReleaseNotesConfig
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$branchName,
        [string[]]$ReleaseNotesFiles
    )

    foreach ($file in $ReleaseNotesFiles)
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
            ReleaseText = []
            BreakingText = []
        }
        Set-Content "$file.json" (ConvertTo-Json $content) -Force -NoNewline -Encoding Ascii
    }

}
