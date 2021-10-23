# TODO: Rename variables
[String]$PreviousDir = $PWD
[String]$CurrentSubProject = ""
[String]$PROJECT_DIR = ""
[HashTable]$projectsTable = @{}
[HashTable]$codeFilesTable =@{}
[HashTable]$projectCodeTable = @{}

enum ProgramLanguage {
    Java
    Kotlin
}

Function Select-Project {
    # TODO: add flags to get java project type and base directory.
    # Scans for sub-projects present in path obtained from first argument passed to the function and 
    # adds them to a projectsTable. Sets alias of the base project's gradlew to pgradlew. 
    # set $DebugPreference = Continue, to enable debug outputs.
    $owd = $PWD
    $global:PROJECT_DIR = $args[0]
    $global:projectsTable = @{}
    $projects = @()
    
    # Making a global alias pgradlew.
    # Use gradlew instead of gradlew.bat to run in a seperate cmd prompt window.
    Set-Alias -Name pgradlew -Value $global:PROJECT_DIR\gradlew.bat -Scope Global

    # Set-Location $global:PROJECT_DIR

    Write-Host "Please wait scanning sub projects. Scanning for the first time after logging in takes a while to load."
    
    # $projectDir = (cmd /c "dir /b /s build.gradle")
    $projectDir = (Get-ChildItem -Path $global:PROJECT_DIR -Filter "build.gradle" -Recurse -Name)
    # $projectDir = [System.IO.Directory]::EnumerateFiles("$global:PROJECT_DIR", "build.gradle", "AllDirectories")

    foreach($javaDir in $projectDir) {
        $projects += @($javaDir.Replace("build.gradle", ""))
    }

    foreach($project in $projects){
        $name = (Get-ProjectName $project)
        Write-Debug "Trying to add $name => $project"
        try {
            $projectsTable.add($name, $project)
        }
        catch {
            Write-Host -ForegroundColor Red "Error trying to add duplicate key '$name'."
        }
    }
    
    Set-Location $owd
}

Function Get-ProjectName {
    # Performs basic name extraction.
    $projectPath = $args[0]
    $projectPath = $projectPath.ToString().Replace("D:\", "")
    $projectPath = $projectPath.Trim('\')

    $splitPath = [String[]] $projectPath.Split("\")
    $splitPathLen = $splitPath.length
    $extractedName = $splitPath[-1]
    $ind = 2
    while ($ind -lt $splitPathLen -and $projectsTable.Contains($extractedName)) {
        $extractedName = $splitPath[-$ind]+"_$extractedName"
        Write-Debug "Extracted Name: $extractedName"   
        $ind += 1
    }

    while ($projectsTable.Contains($extractedName)) {
        $extractedName = $splitPath[0]+"_$extractedName"
    }
    
    if ($extractedName -eq "") {
        return "BaseProject"
    }

    return $extractedName
}

Function Set-Project-Location {
    param($ProjectName)

    # To easily navigate back if previous dir is non-project directory
    $global:PreviousDir = $PWD
    $global:CurrentSubProject = $ProjectName

    # Changes to the specified project. 
    # If no argument is provided changes to PROJECT_DIR
    if (!$ProjectName -or $ProjectName.Equals("")){
        Set-Location $global:PROJECT_DIR
    }
    else {
        if($projectsTable[$ProjectName] -like "$global:PROJECT_DIR*") {
            Set-Location $projectsTable[$ProjectName]
        } else {
            Set-Location $global:PROJECT_DIR\$($projectsTable[$ProjectName])
        }
    }

    if ($PWD.path -ne $global:PROJECT_DIR) {
        Scan-Code
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

Function Open-Files {
    # TODO: Add support for different ide's.
    # Add support to get project name
    # Add support to go to line in the specified file.
    param([String[]]$FileName,
          [String[]]$ProjectName)

    code $codeFilesTable[$FileName]
}

Function Scan-Code {
    # TODO: Add support to load multiple languages
    param([ProgramLanguage]$Language)

    $global:codeFilesTable = @{}

    switch($Language) {
        Java { $extension = '.java' }
        Kotlin { $extension = '.kt' }
        Default { $extension = '.java' }
    }

    Get-ChildItem -Path . -Filter "*$extension" -Recurse -Name | `
        ForEach-Object {
            $codeFileName = $_.Replace($extension, '').ToString().Split('\\')[-1]
            # Write-Host $codeFileName
            # Write-Host $_
            $global:codeFilesTable[$codeFileName] = $_
        }

    Register-ArgumentCompleter -CommandName Open-Files -ParameterName FileName -ScriptBlock $FilesTabCompletion
}

$SubProjectsTabCompletion = {
    param($commandName, $parameterName, $wordToComplete)
    $projectsTable.Keys | ForEach-Object {if($_ -like "$wordToComplete*") {$_} }
}

$FilesTabCompletion = {
    # TODO: Add table to store each project's code files
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    if ($fakeBoundParameters.ProjectName -eq "") {
        $ProjectName = $global:CurrentSubProject
    } else {
        $ProjectName = $fakeBoundParameters.ProjectName
    }
    # echo $ProjectName
    $codeFilesTable.Keys | ForEach-Object {if($_ -like "$wordToComplete*") {$_} }
}

# Adding sub-project tab completion
Register-ArgumentCompleter `
-CommandName Set-Project-Location, Build-Project, Open-Files `
-ParameterName ProjectName `
-ScriptBlock $SubProjectsTabCompletion

# To see and navigate between all available autocomplete words
Set-PSReadLineKeyHandler -Chord Ctrl+Tab -Function MenuComplete
