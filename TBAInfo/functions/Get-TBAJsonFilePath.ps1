function Get-TBAJsonFilePath {
    <#
        .SYNOPSIS
            Retrieves the full path to the TBA.json file located in the TBAInfo module directory.

        .DESCRIPTION
            This function locates the TBAInfo module on the system and constructs the full path
            to the TBA.json file assumed to be in the same directory.

        .OUTPUTS
            System.String
            Returns the full file path to TBA.json if the module is found.

        .EXAMPLE
            PS> Get-TBAJsonFilePath
            C:\Program Files\WindowsPowerShell\Modules\TBAInfo\TBA.json

        .NOTES
            Written By: Jeff Brusoe
            Last Updated: May 25, 2025
    #>

    [OutputType([string])]
    [CmdletBinding()]
    param (

    )

    try {
        $JsonConfigModule = Get-Module -ListAvailable TBAInfo -ErrorAction Stop
            | Select-Object -First 1

        if (-not $JsonConfigModule) {
            throw "The TBAInfo module could not be found."
        }
        else {
            Write-Verbose "Found TBAInfo module"
        }

        Write-Verbose "Determining path to JSON file"
        $JoinPathParams = @{
            Path = $(Split-Path -Path $JsonConfigModule.Path -Parent -ErrorAction Stop)
            ChildPath = "TBA.json"
            ErrorAction = "Stop"
        }
        $JsonFilePath = Join-Path @JoinPathParams

        if (-not (Test-Path -Path $JsonFilePath)) {
            throw [System.IO.FileNotFoundException]::new("The TBA.json file was not found in the TBAInfo module directory.")
        }
        else {
            Write-Verbose "TBA.json was found"
        }

        Write-Verbose "JSON File Path $JsonFilePath"
        Write-Output $JsonFilePath
    }
    catch {
        throw "Error in Get-TBAJsonFilePath"
    }
}