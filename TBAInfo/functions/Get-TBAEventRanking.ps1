
function Get-TBAEventRanking {
    <#
        .SYNOPSIS
            Retrieves team rankings for a specified FIRST Robotics Competition (FRC) event.

        .DESCRIPTION
            This function uses The Blue Alliance (TBA) API to retrieve and display team rankings 
            for a given FRC event. It returns a list of teams with their rank, team number, 
            team name, win/loss/tie record, and number of matches played.

        .PARAMETER EventKey
            The unique identifier for the FRC event (e.g., "2025ohcl"). 
            If not provided, it defaults to the result of Get-TBAJsonEventKey.
            This parameter also accepts input from the pipeline.

        .EXAMPLE
            Get-TBAEventRanking -EventKey "2025ohcl"

            Returns the event rankings with the event key passed in as a parameter.

            Rank           : 1
            Team_Number    : 4611
            Team_Name      : OZone
            Wins           : 10
            Losses         : 0
            Ties           : 0
            Matches_Played : 10

        .EXAMPLE
            "2025ohcl" | Get-TBAEventRanking | Format-Table

            Returns the event rankings with the event key being passed in from the pipeline
            and displays the output as a table.

            Rank Team_Number Team_Name Wins Losses Ties Matches_Played
            ---- ----------- --------- ---- ------ ---- --------------
            1 4611        OZone       10      0    0             10
            2 4145        WorBots      9      1    0             10
            3 1787        The Flyi…   10      0    0             10
            4 2228        CougarTe…    8      2    0             10
            5 1511        Rolling …    7      3    0             10
            6 4121        Viking  …    8      2    0             10
            7 6964        BearBots     8      2    0             10
            8 3173        IgKnight…    6      4    0             10

        .NOTES
            Requires the Get-TBAData and Get-TBATeamName functions to be defined in your environment.
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidatePattern("^\d{4}[a-zA-Z]{1,6}$")]
        [string]$EventKey = $(Get-TBAJsonEventKey)
    )

    process {
        try {
            $Params = @{
                DataToDownload = "EventRanking"
                EventKey       = $EventKey
                ErrorAction    = "Stop"
            }

            $EventRankings = Get-TBAData @Params | ConvertFrom-Json -ErrorAction Stop

            foreach ($Ranking in $EventRankings.rankings) {
                Write-Verbose "Processing TeamKey: $($Ranking.team_key)"

                $TeamKey    = $Ranking.team_key
                $TeamNumber = $TeamKey -replace "frc", ""
                $TeamName   = Get-TBATeamName -TeamKey $TeamKey

                [PSCustomObject]@{
                    Rank           = $Ranking.rank
                    Team_Number    = $TeamNumber
                    Team_Name      = $TeamName
                    Wins           = $Ranking.record.wins
                    Losses         = $Ranking.record.losses
                    Ties           = $Ranking.record.ties
                    Matches_Played = $Ranking.matches_played
                }
            }
        }
        catch {
            Write-Warning "Failed to retrieve rankings for event '$EventKey'. Error: $_"
        }
    }
}