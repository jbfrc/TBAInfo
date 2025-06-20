function Get-TBAJsonConfig {
    <#
        .SYNOPSIS
            Reads a JSON file and extracts the values of 'api_key', 'team_key', and 'event_key'.

        .DESCRIPTION
            This function reads a JSON file (defaulting to 'TBA.json' in the same directory as the 'TBAInfo' module),
            parses its contents, and returns the values of the 'api_key', 'team_key', and 'event_key' fields if they exist.
            It includes error handling for missing files and missing fields.

        .PARAMETER JsonFilePath
            The full path to the JSON file that contains the required fields.
            If not specified, the function attempts to locate 'TBA.json' in the TBAInfo module directory.

        .OUTPUTS
            PSCustomObject
            Returns an object with 'api_key', 'team_key', and 'event_key' properties.

        .EXAMPLE
            Get-TBAJSONConfig
            team_key event_key api_key
            -------- --------- -------
            frc4611  2025ohcl  <MyAPIKey>

            (Assumes TBA.json is in the TBAInfo module directory)

        .EXAMPLE
            Get-TBAJSONConfig -JsonFilePath "C:\data\TBA.json"
            team_key event_key api_key
            -------- --------- -------
            frc4611  2025ohcl  <MyAPIKey>

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 25, 2025

            To Do:
            1. Parameter Validation
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [string]$JsonFilePath = $(Get-TBAJsonFilePath)
    )

    Write-Verbose "Path to JSON File: $JsonFilePath"

    try {
        $GetContentParams = @{
            Path = $JsonFilePath
            Raw = $true
            ErrorAction = "Stop"
        }
        $JsonContent = Get-Content @GetContentParams | ConvertFrom-Json

        [PSCustomObject]@{
            team_key  = $JsonContent.team_key
            event_key = $JsonContent.event_key
            api_key   = $JsonContent.api_key
        }
    } catch {
        throw "Failed to read or parse the JSON file"
    }
}