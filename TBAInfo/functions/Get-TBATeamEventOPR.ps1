function Get-TBATeamEventOPR {
<#
    .SYNOPSIS
        Retrieves OPR, DPR, and CCWM statistics for a specific FRC team at a given event.

    .DESCRIPTION
        This function uses The Blue Alliance (TBA) API data to extract Offensive Power Rating (OPR),
        Defensive Power Rating (DPR), and Calculated Contribution to Winning Margin (CCWM) for a
        specified team at a specified event.

    .PARAMETER EventKey
        The event key (e.g., "2025ohcl") for which to retrieve team statistics.
        If not provided, it defaults to the result of Get-TBAJsonEventKey.

    .PARAMETER TeamKey
        The team key (e.g., "frc4611") for which to retrieve statistics.
        If not provided, it defaults to the result of Get-TBAJsonTeamKey.

    .OUTPUTS
        [PSCustomObject] containing TeamKey, EventKey, TeamNumber, OPR, DPR, and CCWM.

    .EXAMPLE
        Get-TBATeamEventOPR -TeamKey "frc4611" -EventKey "2025ohcl" -Verbose

    .NOTES
        Written by: Jeff Brusoe
        Last Updated: June 15, 2025
#>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [ValidatePattern("^\d{4}[a-zA-Z]{1,6}$")]
        [string]$EventKey = $(Get-TBAJsonEventKey),

        [ValidatePattern("\b(?:frc\d{1,5}|\d{1,5})\b")]
        [string]$TeamKey = $(Get-TBAJsonTeamKey)
    )

    try {
        if ($TeamKey -notlike "*frc*") {
            $TeamNumber = $TeamKey
            $TeamKey = "frc" + $TeamKey
        }
        else {
            Write-Verbose "Extracting team number from team key: $TeamKey"
            $TeamNumber = $TeamKey -replace '^frc',''
        }

        
        $TeamNumber = $TeamKey -replace '^frc', ''

        Write-Verbose "Retrieving OPR data for event: $EventKey"
        $EventOPRs = Get-TBAEventOPR -EventKey $EventKey -ErrorAction Stop

        Write-Verbose "Searching for team number $TeamNumber in event OPR data"
        $TeamEventOPR = $EventOPRs | Where-Object { $_.TeamNumber -eq $TeamNumber }

        if (-not $TeamEventOPR) {
            Write-Warning "No OPR data found for team $TeamKey at event $EventKey."
            return
        }

        Write-Verbose "Returning OPR data for team $TeamKey"
        return [PSCustomObject]@{
            TeamKey    = $TeamKey
            EventKey   = $EventKey
            TeamNumber = $TeamNumber
            OPR        = $TeamEventOPR.OPR
            DPR        = $TeamEventOPR.DPR
            CCWM       = $TeamEventOPR.CCWM
        }
    }
    catch {
        Write-Error "Error retrieving OPR info for $TeamKey at $EventKey : $_"
    }
}