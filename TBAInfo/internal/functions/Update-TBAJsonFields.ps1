function Update-TBAJsonFields {
    <#
        .SYNOPSIS
            Updates one or more fields (team_key, event_key, api_key) in a TBA JSON file.

        .DESCRIPTION
            This function modifies specific fields in a JSON file used for The Blue Alliance (TBA) API integration.
            It allows updating the `team_key`, `event_key`, and `api_key` fields individually. Only the parameters
            provided will be updated in the JSON file. The function reads the existing JSON, updates the specified
            fields, and writes the updated content back to the file.

        .PARAMETER TeamKey
            The team identifier in the format "frcXXXX", where XXXX is the team number. This value will replace the
            existing `team_key` field in the JSON file.

        .PARAMETER EventKey
            The event identifier (e.g., "2025ohcl"). This value will replace the existing `event_key` field in the JSON file.

        .PARAMETER ApiKey
            The API key used to authenticate with The Blue Alliance API. This value will replace the existing `api_key` field.

        .PARAMETER JsonFilePath
            The full path to the JSON file to be updated. If not specified, the function will call `Get-TBAJsonFilePath`
            to determine the default path.

        .EXAMPLE
            Update-TBAJsonFields -TeamKey "frc1234" -EventKey "2025ohcl"
    
            Updates the `team_key` and `event_key` fields in the default TBA JSON file.

        .EXAMPLE
            Update-TBAJsonFields -ApiKey "abc123xyz" -JsonFilePath "C:\Configs\tba.json"

            Updates only the `api_key` field in the specified JSON file.

        .NOTES
            Author: Jeff Brusoe
            Last Updated: June 1, 2025
        #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidatePattern("^frc\d+$|^\d+$")]
        [string]$TeamKey,

        [Parameter()]
        [string]$EventKey,

        [Parameter()]
        [string]$ApiKey,

        [Parameter()]
        [string]$JsonFilePath = $(Get-TBAJsonFilePath)
    )

    process {
        Write-Verbose "Updating fields in JSON file"

        if (-not (Test-Path $JsonFilePath)) {
            Write-Error "File not found: $JsonFilePath"
            return
        }

        try {
            $JsonContent = Get-Content -Path $JsonFilePath -Raw | ConvertFrom-Json

            if ($PSBoundParameters.ContainsKey('TeamKey')) {
                Write-Verbose "Updating team_key to '$TeamKey'"
                $JsonContent.team_key = $TeamKey
            }

            if ($PSBoundParameters.ContainsKey('EventKey')) {
                Write-Verbose "Updating event_key to '$EventKey'"
                $JsonContent.event_key = $EventKey
            }

            if ($PSBoundParameters.ContainsKey('ApiKey')) {
                Write-Verbose "Updating api_key to '$ApiKey'"
                $JsonContent.api_key = $ApiKey
            }

            $JsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $JsonFilePath
            Write-Output "Fields updated successfully in file '$JsonFilePath'."
        } catch {
            Write-Error "An error occurred while processing the file: $_"
        }
    }
}