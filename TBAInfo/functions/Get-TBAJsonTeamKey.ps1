function Get-TBAJsonTeamKey {
    <#
        .SYNOPSIS
            Retrieves the team key (such as 'frc4611') from the TBA JSON configuration file.

        .DESCRIPTION
            This function reads a JSON configuration file and extracts the value of the `team_key` property.
            It includes error handling for invalid JSON and missing keys.

            This function assumes that the JSON file contains a `team_key` field at the root level.

        .PARAMETER JsonFilePath
            The full path to the JSON configuration file. If not specified, the function will use a default path
            as defined in the `Get-TBAJSONConfig` function.

        .OUTPUTS
            System.String

        .EXAMPLE
            Get-TBAJSONTeamKey -JsonFilePath "C:\Configs\tba_config.json"
            Returns the team key from the specified JSON file.

        .EXAMPLE
            Get-TBAJSONTeamKey
            Returns the team key using the default JSON file path.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 25, 2025
    #>

    [OutputType([string])]
    [CmdletBinding()]
    param (
        [string]$JsonFilePath = $(Get-TBAJsonFilePath)
    )

    try {
        Write-Verbose "Retrieving configuration using Get-TBAJSONConfig..."
        $config = Get-TBAJSONConfig -JsonFilePath $JsonFilePath

        Write-Verbose "Checking for 'team_key' in the configuration..."
        if (-not $config.team_key) {
            throw "The 'team_key' property was not found in the JSON configuration."
        }

        Write-Verbose "'team_key' found. Returning value: $($config.team_key)"
        Write-Output $config.team_key
    }
    catch {
        Write-Error "Failed to retrieve team key: $_"
    }
}