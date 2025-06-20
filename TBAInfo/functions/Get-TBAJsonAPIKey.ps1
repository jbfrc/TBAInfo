function Get-TBAJsonAPIKey {
    <#
        .SYNOPSIS
            Retrieves the API key from a TBA JSON configuration file.

        .DESCRIPTION
            This function reads a JSON configuration file and extracts the value of the `api_key` property.
            It includes error handling for missing files, invalid JSON, and missing keys.

            This function assumes that the JSON file contains an `api_key` field at the root level.

        .PARAMETER JsonFilePath
            The full path to the JSON configuration file. If not specified, the function will use a default path
            as defined in the `Get-TBAJSONConfig` function.

        .OUTPUTS
            System.String

        .EXAMPLE
            Get-TBAJsonAPIKey -JsonFilePath "C:\Configs\tba_config.json"
            Returns the API key from the specified JSON file.

        .EXAMPLE
            Get-TBAJsonAPIKey
            Returns the API key using the default JSON file path.

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
        Write-Verbose "Reading TBA Config File"
        $TBAConfig = Get-TBAJsonConfig -JsonFilePath $JsonFilePath -ErrorAction Stop

        if (-not $TBAConfig.api_key) {
            throw "The 'api_key' property was not found in the JSON configuration."
        }
        else {
            Write-Verbose "API Key has been read"
        }

        Write-Output $TBAConfig.api_key
    }
    catch {
        Write-Error "Failed to retrieve API key: $_"
    }
}