function Get-TBAJsonEventKey {
    <#
        .SYNOPSIS
            Retrieves the event key (such as '2025miket') from the TBA JSON configuration file.

        .DESCRIPTION
            This function reads a JSON configuration file and extracts the value of the `event_key` property.
            It includes error handling for invalid JSON and missing keys.

            This function assumes that the JSON file contains an `event_key` field at the root level.

        .PARAMETER JsonFilePath
            The full path to the JSON configuration file. If not specified, the function will use a default path
            as defined in the `Get-TBAJSONConfig` function.

        .OUTPUTS
            System.String

        .EXAMPLE
            Get-TBAJsonEventKey -JsonFilePath "C:\Configs\tba_config.json"

            Returns the event key from the specified JSON file.

        .EXAMPLE
            Get-TBAJsonEventKey

            Returns the event key using the default JSON file path.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 30, 2025
    #>

    [OutputType([string])]
    [CmdletBinding()]
    param (
        [string]$JsonFilePath = $(Get-TBAJsonFilePath)
    )

    try {
        Write-Verbose "Retrieving configuration using Get-TBAJSONConfig..."
        $config = Get-TBAJSONConfig -JsonFilePath $JsonFilePath

        Write-Verbose "Checking for 'event_key' in the configuration..."
        if (-not $config.event_key) {
            throw "The 'event_key' property was not found in the JSON configuration."
        }

        Write-Verbose "'event_key' found. Returning value: $($config.event_key)"
        Write-Output $config.event_key
    }
    catch {
        Write-Error "Failed to retrieve event key: $_"
    }
}