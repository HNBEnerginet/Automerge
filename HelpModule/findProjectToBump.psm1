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
        return
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
                return $true;
            }
        }
    }

    Write-Host "No build files edited"
    return $false;
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
    pattern = re.compile(r'Pattern:(\S+)')

    $projectNameSpace =""

    if ($file_content -match $pattern) {
        $projectNameSpace = $matches[1]
    }else{
        write-host "Could not find related project"
        return $false
    }

    foreach ($editedFile in $editedFiles)
    {
        Switch -Wildcard ($editedFile) {
            "*/packages.lock.json" { break; }
            "*/*.csproj" { break; }
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
        $projectNameSpace = $matches[0]
        Write-Host "Project name space: $projectNameSpace"
    }else{
        write-host "Could not find related project"
        return $false
    }

    foreach ($editedFile in $editedFiles)
    {
        Switch -Wildcard ($editedFile) {
            "*/Source/$projectNameSpace/packages.lock.json" {
                return $true
            }
        }
    }

    Write-Host "No project files where updated"
    return $false;
}
