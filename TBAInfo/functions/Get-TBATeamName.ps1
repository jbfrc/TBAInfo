function Get-TBATeamName {
    <#
        .SYNOPSIS
            Retrieves the nickname of an FRC team from The Blue Alliance (TBA) API.

        .DESCRIPTION
            This function takes a team key (such as "frc4611") and queries The Blue Alliance API
            to retrieve the team's nickname. It uses Get-TBAData to make the API call and
            handles errors and non-ASCII characters in the response.

        .PARAMETER TeamKey
            The unique identifier of the FRC team (e.g., "frc4611").

        .OUTPUTS
            System.String

        .OUTPUTS
            The nickname (name) of the team as a string. If the nickname is not found, returns "Unknown".

        .EXAMPLE
            Get-TBATeamName frc4611
            OZone

            Returns the team name of FRC 4611 (Ozone)

        .EXAMPLE
            "frc4611" | Get-TBATeamName
            OZone

            Also accepts pipeline input of team key.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: June 6, 2025
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("\b(?:frc\d{1,5}|\d{1,5})\b")]
        [string]$TeamKey
    )

    begin {
        Write-Verbose "Starting Get-TBATeamName"
    }

    process {
        try {
            if ($TeamKey -notlike "*frc*") {
                $TeamKey = "frc" + $TeamKey
            }

            Write-Verbose "Starting Get-TBATeamName for team key: $TeamKey"

            Write-Verbose "Parsing JSON response..."
            $TeamInfo = Get-TBAData -DataToDownload "TeamName" -TeamKey $TeamKey -ErrorAction Stop |
                            ConvertFrom-Json -ErrorAction Stop
            $TeamName = $TeamInfo.nickname

            if (-not $TeamName) {
                Write-Verbose "Nickname not found in response. Defaulting to 'Unknown'."
                $TeamName = "Unknown"
            }

            Write-Verbose "Filtering non-ASCII characters from nickname..."
            $TeamName = $TeamName -replace '[^\x00-\x7F]', ''
        }
        catch {
            throw "Error retrieving team information for '$TeamKey': $($_.Exception.Message)"
        }
    }

    end {
        Write-Verbose "Returning team nickname: $TeamName"
        Write-Output $TeamName
    }
}