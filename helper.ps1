# TODO: Rename variables
[String]$PreviousDir = $PWD
[String]$PROJECT_DIR = ""
[String[]]$projects = @()
[HashTable]$projectsTable = @{}
[HashTable]$codeFilesTable =@{}

Function Select-Project {
    # TODO: add flags to get java project type and base directory.
    # Scans for sub-projects present in path obtained from first argument passed to the function and 
    # adds them to a projectsTable. Sets alias of the base project's gradlew to pgradlew. 
    # set $DebugPreference = Continue, to enable debug outputs.
    $owd = $PWD
    $global:PROJECT_DIR = $args[0]
    $global:projectsTable = @{}
    
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
        $name = (Get-Project-Name $project)
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

Function Get-Project-Name {
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

    return $extractedName
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
        if($projectsTable[$ProjectName] -like "$PROJECT_DIR*") {
            Set-Location $projectsTable[$ProjectName]
        } else {
            Set-Location $global:PROJECT_DIR\$($projectsTable[$ProjectName])
        }
    }

    if ($PWD.path != $global:PROJECT_DIR) {
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

Function Open-File {
    # TODO: Add functionality to open multiple files
    param($FileName)

    code $codeFilesTable[$FileName]
}

Function Scan-Code {
    Get-ChildItem -Path . -Filter "*.java" -Recurse -Name | ` 
    ForEach-Object {
        $codeFileName = $_.Replace('.java', '').ToString().Split('\\')[-1]
        Write-Host $codeFileName
        Write-Host $_
        $codeFilesTable[$codeFileName] = $_
    }

    Register-ArgumentCompleter -CommandName Open-File -ParameterName FileName -ScriptBlock $FilesTabCompletion
}

$SubProjectsTabCompletion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $projectsTable.Keys | ForEach-Object {if($_ -like "$wordToComplete*") {$_} }
}

$FilesTabCompletion = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $codeFilesTable.Keys | ForEach-Object {if($_ -like "$wordToComplete*") {$_} }
}

Register-ArgumentCompleter -CommandName Set-Project-Location -ParameterName ProjectName -ScriptBlock $SubProjectsTabCompletion
Register-ArgumentCompleter -CommandName Build-Project -ParameterName ProjectName -ScriptBlock $SubProjectsTabCompletion

# To see and navigate between all  available autocomplete options
Set-PSReadLineKeyHandler -Chord Ctrl+Tab -Function MenuComplete
