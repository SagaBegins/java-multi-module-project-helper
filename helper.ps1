# TODO: Rename variables
[String]$PROJECT_DIR = ""
[String[]]$projects = @()
[HashTable]$projectsTable = @{}

function Select-Project {
    # TODO: add flags to get java project type and base directory.
    # Scans for sub-projects present in path obtained from first argument passed to the function and 
    # adds them to a projectsTable. Sets alias of the base project's gradlew to pgradlew. 
    $owd = $PWD
    $global:PROJECT_DIR = $args[0]
    
    # Making a global alias pgradlew.
    Set-Alias -Name pgradlew -Value $global:PROJECT_DIR\gradlew -Scope Global

    Set-Location $global:PROJECT_DIR

    Write-Host "Please wait scanning sub projects. Scanning for the first time after logging in takes a while to load."
    
    $projectDir = (cmd /c "dir /b /s build.gradle")

    foreach($javaDir in $projectDir) {
        $projects += @($javaDir.Replace("build.gradle", ""))
    }

    foreach($project in $projects){
        $name = (Get-Project-Name $project)
        Write-Host "Trying to add "$name ':' $project
        try {
            $projectsTable.add($name, $project)
        }
        catch {
            Write-Host -ForegroundColor Red "Error trying to add duplicate key '$name'."
        }
        Write-Host ""
    }
    
    Set-Location $owd
}

function Get-Project-Name {
    # TODO: Complete Name extraction
    # Performs basic name extraction. Currently, only Works properly with sub-projects having distinct folder names.
    $projectPath = $args[0]
    $projectPath = $projectPath.ToString().Replace("D:\", "")
    $projectPath = $projectPath.Trim('\')

    $splitPath = [String[]] $projectPath.Split("\")
    
    Write-Host "Extracted Name: $($splitPath[-1])"
    return $splitPath[-1]
}

function Set-Project-Location {
    # Changes to the specified project. 
    # If no argument is provided changes to PROJECT_DIR
    if (!$args[0] -or $args[0].Equals("")){
        Set-Location $global:PROJECT_DIR
    }
    else {
        Set-Location $projectsTable[$args[0]]
    }
}
