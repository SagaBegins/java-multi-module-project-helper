# Java Subproject Helper

## Description

java-helper makes navigating between, building and running java subprojects easier. Currently supports gradle projects but can be modified to support others.

## Usage of helper.ps1

    powershell -noexit -executionpolicy bypass -File <path to helper.ps1>
    
## Usage

    source <path to helper> [options]

Options supported by java-helper

- `-n|--no-info`: Does not print helper info.
- `-v|--vpn`: Connects to openvpn server.
- `-c|--chdir`: Changes directory to Base of project.
- `-p|--custom-ps1`: Uses custom ps1

Most of the commands available have `-h|--help` option to describe how the command can be used.

Some commands which java-helper supports

- `helper_info`: Prints some helpful information.
- `chdir <project-name>`: Change directory between subprojects.
- `bld [project-name] [options]`: Clean builds a specific project.
- `btrun [project-name] [options]`: Runs spring boot project.
- `show_jacoco [project-name]`: Opens the java code coverage html of the specified project or current directory if nothing is provided.
- `show_checkstyle [project-name]`: Opens the checkstyle html of the specified project or current directory if nothing is provided.
- `edit_config`: Opens config in gedit.
- `edit_helper`: Opens helper in gedit.
