function Get-TBATeamEventMatchInfo {
    <#
        .SYNOPSIS
            Retrieves and summarizes match information for a specific team at a specific FRC event.

        .DESCRIPTION
            The Get-TBATeamEventMatchInfo function queries The Blue Alliance (TBA) API to retrieve
            match data for a given team at a specified event. It processes the match data to provide
            a simplified summary including the match key, a human-readable
            description (e.g., "Qualifying Match 3"), and whether the match has been completed.

        .PARAMETER TeamKey
            The team key (e.g., "frc4611") for which to retrieve match data.
            If not provided, the function attempts to retrieve it using Get-TBAJsonTeamKey.

        .PARAMETER EventKey
            The event key (e.g., "2025ohcl") for which to retrieve match data.
            If not provided, the function attempts to retrieve it using Get-TBAJsonEventKey.

        .OUTPUTS
            PSCusomObject with MatchKey, Description, and MatchCompleted fields.

        .EXAMPLE
            Get-TBATeamEventMatchInfo -TeamKey "frc1114" -EventKey "2025onwat"

            Retrieves and summarizes match information for team 1114 at the 2025 Waterloo event.

        .EXAMPLE
            Get-TBATeamEventMatchInfo

            Retrieves match information using default team and event keys from helper functions.

        .NOTES
        Written By: Jeff Brusoe  
        Last Updated: June 15, 2025
    #>

    [CmdletBinding()]
    param (
        [ValidatePattern("\b(?:frc\d{1,5}|\d{1,5})\b")]
        [string]$TeamKey = $(Get-TBAJsonTeamKey),

        [ValidatePattern("^\d{4}[a-zA-Z]{1,6}$")]
        [string]$EventKey = $(Get-TBAJsonEventKey)
    )

    try {
        if ($TeamKey -notlike "*frc*") {
            Write-Verbose "Current Team Key: $TeamKey"
            $TeamKey = "frc" + $TeamKey
            Write-Verbose "Updated Team Key: $TeamKey"
        }

        Write-Verbose "Making API call"
        $MatchInfoResponse = Get-TBAData -DataToDownload "TeamMatch" -EventKey $EventKey -TeamKey $TeamKey

        $MatchInfo = $MatchInfoResponse | ConvertFrom-Json
        $MatchInfo = $MatchInfo | Sort-Object -Property "predicted_time"

        foreach ($Match in $MatchInfo) {
            $MatchKey = $Match.key

            $MatchDescription = ""

            if ($Match.comp_level -eq "qm") {
                $MatchDescription = "Qualifying Match " + $Match.match_number
            }
            elseif ($Match.comp_level -eq "sf") {
                $MatchDescription = "Semifinal Match " + $Match.set_number
            }
            elseif ($Match.comp_level -eq "f") {
                $MatchDescription = "Final " + $Match.match_number
            }

            if ($Match.winning_alliance -ne "") {
                $MatchCompleted = $true
            }
            else {
                $MatchCompleted = $false
            }

            [PSCustomObject]@{
                "MatchKey" = $MatchKey
                "Description" = $MatchDescription
                "MatchCompleted" = $Matchcompleted
            }
        }
    }
    catch {
        Write-Error "Unable to get list of team matches"
    }
}