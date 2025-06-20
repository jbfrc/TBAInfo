function Get-TBATeamEventMatchKey {
    <#
        .SYNOPSIS
            Retrieves a list of match keys for a specified FRC team from The Blue Alliance (TBA) API.

        .DESCRIPTION
            This function calls the Get-TBATeamMatch command to retrieve match data for a given FRC team key.
            It supports pipeline input and extracts the match keys associated with each team.

        .PARAMETER TeamKey
            The team key in the format 'frcXXXX' (e.g., 'frc4611').
            This parameter accepts input from the pipeline and can be passed positionally.

        .PARAMETER EventKey
            The event key for the FRC event (e.g., "2025ohcl").
            If not provided, the function attempts to retrieve it using Get-TBAJsonEventKey.

        .OUTPUTS
            System.String[]
            An array of match key strings.

        .EXAMPLE
            "frc4611" | Get-TBATeamEventMatchKey
            Retrieves match keys for a team via the pipeline.

        .EXAMPLE
            Get-TBATeamEventMatchKey -TeamKey "frc4611"
            Retrieves all match keys for team 4611.

        .EXAMPLE
            Get-TBATeamEventMatchKey "frc1678"
            Uses positional parameter to retrieve match keys for team 1678.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 25, 2025
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidatePattern("\b(?:frc\d{1,5}|\d{1,5})\b")]
        [string]$TeamKey = $(Get-TBAJsonTeamKey),

        [string]$EventKey = $(Get-TBAJsonEventKey)
    )

    process {
        try {
            if ($TeamKey -notlike "*frc*") {
                Write-Verbose "Changing Team Key"
                $TeamKey = "frc" + $TeamKey
            }

            $TeamMatches = Get-TBATeamEventMatchInfo -TeamKey $TeamKey

            if ($TeamMatches) {
                $MatchKeys = $TeamMatches | Select-Object MatchKey
                Write-Output $MatchKeys
            }
            else {
                Write-Warning "No matches found for team key '$TeamKey'."
            }
        }
        catch {
            Write-Error "An error occurred while retrieving match keys for '$TeamKey': $_"
        }
    }
}