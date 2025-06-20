function Update-TBAJsonApiKey {
    <#
        .SYNOPSIS
            Updates the api_key field in a TBA JSON file.

        .DESCRIPTION
            This is a wrapper around Update-TBAJsonFields that simplifies updating
            just the api_key field. It includes error handling and supports pipeline input.

        .PARAMETER ApiKey
            The new API key to set in the JSON file.

        .EXAMPLE
            Update-TBAJsonApiKey -ApiKey "my-secret-api-key"

            Updates the api_key field in the JSON config file.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: June 1, 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [string]$ApiKey
    )

    process {
        try {
            Write-Verbose "Calling Update-TBAJsonFields to update api_key"
            Update-TBAJsonFields -ApiKey $ApiKey -ErrorAction Stop
            Write-Verbose "Successfully updated API key in JSON file"
        } catch {
            Write-Error "Failed to update api_key: $_"
        }
    }
}