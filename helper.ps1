# TODO: Rename variables
[String]$PreviousDir = $PWD
[String]$PROJECT_DIR = ""
[String[]]$projects = @()
[HashTable]$projectsTable = @{}

Function Select-Project {
    # TODO: add flags to get java project type and base directory.
    # Scans for sub-projects present in path obtained from first argument passed to the function and 
    # adds them to a projectsTable. Sets alias of the base project's gradlew to pgradlew. 
    $owd = $PWD
    $global:PROJECT_DIR = $args[0]
    
    # Making a global alias pgradlew.
    # Use gradlew instead of gradlew.bat to run in a seperate cmd prompt window.
    Set-Alias -Name pgradlew -Value $global:PROJECT_DIR\gradlew.bat -Scope Global

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

Function Get-Project-Name {
    # TODO: Complete Name extraction
    # Performs basic name extraction. Currently, only Works properly with sub-projects having distinct folder names.
    $projectPath = $args[0]
    $projectPath = $projectPath.ToString().Replace("D:\", "")
    $projectPath = $projectPath.Trim('\')

    $splitPath = [String[]] $projectPath.Split("\")
    
    Write-Host "Extracted Name: $($splitPath[-1])"
    return $splitPath[-1]
}

Function Set-Project-Location {
    param($ProjectName)

    # To easily navigate back if previous dir is non-project directory
    $global:PreviousDir = $PWD
    
    # Changes to the specified project. 
    # If no argument is provided changes to PROJECT_DIR
    if (!$ProjectName -or $ProjectName.Equals("")){
        Set-Location $global:PROJECT_DIR
    }
    else {
        Set-Location $projectsTable[$ProjectName]
    }
}

Function Build-Project {
    # Builds the specified project. 
    # TODO Add function with all gradle tasks for the specified project.
    param($ProjectName)

    Set-Project-Location $ProjectName
    try {    
        pgradlew build
    } catch {
        Write-Host -Color Red "Something went wrong."
    } finally {
        cd $PreviousDir
    }
}


$SubProjectsTabCompletion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $projectsTable.Keys | ForEach-Object {if($_ -like "$wordToComplete*") {$_} }
}

Register-ArgumentCompleter -CommandName Set-Project-Location -ParameterName ProjectName -ScriptBlock $SubProjectsTabCompletion
Register-ArgumentCompleter -CommandName Build-Project -ParameterName ProjectName -ScriptBlock $SubProjectsTabCompletion

# To see and navigate between all  available autocomplete options
Set-PSReadLineKeyHandler -Chord Ctrl+Tab -Function MenuComplete
