function Get-TBAAllTeamListByYear {
    <#
        .SYNOPSIS
            Retrieves a list of all FRC teams for a given year from The Blue Alliance (TBA) API.

        .DESCRIPTION
            This function queries The Blue Alliance API using a helper function to retrieve all registered FRC teams
            for a specified year. It handles pagination and returns a list of team objects with key details.

        .PARAMETER Year
            The competition year for which to retrieve the list of teams. Must be a 4-digit year.

        .OUTPUTS
            PSCustomObject[]
            Returns an array of custom objects, each representing a team with properties:
            team_number, name, key, city, state_prov, and country.

        .EXAMPLE
            Get-TBAAllTeamListByYear -Year 2025

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: June 13, 2025

            Requires a valid TBA API key and a helper function `Get-TBAHeader`.
            Assumes `$BaseURL` is defined elsewhere in the module.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidatePattern("^\d{4}$")]
        [ValidateRange(1992, 2026)]
        [string]$Year = (Get-Date).Year.ToString()
    )

    begin {
        $PageNum = 0
        $MaxRetries = 3

        Write-Verbose "Getting All Teams List"
    }

    process {
        while ($true) {
            Write-Verbose "Current PageNum: $PageNum"

            $GetTBAParams = @{
                DataToDownload = "AllTeamsList"
                PageNum        = $PageNum
                Year           = $Year
                ErrorAction    = "Stop"
            }

            $TBAResponse = Invoke-TBARetry {
                Get-TBAData @GetTBAParams
            }

            if (-not $TBAResponse) {
                Write-Verbose "No valid response received after $MaxRetries attempts. Ending pagination."
                break
            }

            try {
                $TBAData = $TBAResponse | ConvertFrom-Json
                Write-Verbose "Successfully parsed JSON response for page $PageNum."
            } catch {
                Write-Error "Failed to parse JSON response on page $PageNum"
                break
            }

            if (-not $TBAData) {
                Write-Verbose "Empty response array on page $PageNum. Ending pagination."
                break
            }

            foreach ($Team in $TBAData) {
                Write-Verbose "Current Team: $($Team.team_number)"
                Write-Verbose "$($Team.nickname)"

                [PSCustomObject]@{
                    team_number = $Team.team_number
                    name        = $Team.nickname
                    key         = $Team.key
                    city        = $Team.city
                    state_prov  = $Team.state_prov
                    country     = $Team.country
                }
            }

            $PageNum++
        }
    }
}