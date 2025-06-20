function Get-TBAData {
    <#
        .SYNOPSIS
            Retrieves data from The Blue Alliance (TBA) API.
        
        .DESCRIPTION
            The Get-TBAData function is a flexible interface for retrieving various types of data
            from The Blue Alliance (TBA) API, which provides information about FIRST Robotics Competition (FRC)
            teams, events, and match statistics.

            Based on the specified DataToDownload parameter, the function dynamically constructs
            the appropriate API endpoint and sends a request using the required authentication headers.
            It supports downloading event lists, team lists, team details, match data, and performance
            metrics such as OPR and COPR.

        .PARAMETER DataToDownload
            The type of data to download (e.g., AllEventsList, AllTeamsList, etc.)

        .PARAMETER Year
            The year for which to retrieve data. Defaults to the current year.

        .PARAMETER EventKey
            The event key used for event-specific queries.

        .PARAMETER TeamKey
            The team key used for team-specific queries.

        .PARAMETER PageNum
            The page number for paginated requests (e.g., team lists).

        .EXAMPLE
            Get-TBAData -DataToDownload AllEventsList -Year 2025

            Retrieves a list of all events for the year 2025.

        .EXAMPLE
            Get-TBAData -DataToDownload EventOPR -EventKey 2025ohcl

            Retrieves Offensive Power Ratings (OPR) for the event with key '2025ohcl'.

        .NOTES
            Written By: Jeff Brusoe
            Last Updated: June 15, 2025
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidateSet("AllEventsList", "AllTeamsList", "TeamName", "EventOPR", "EventCOPR", "TeamMatch","EventRanking")]
        [string]$DataToDownload,

        [string]$Year = (Get-Date).Year.ToString(),
        [string]$EventKey = $(Get-TBAJsonEventKey),
        [string]$TeamKey = $(Get-TBAJsonTeamKey),
        [int]$PageNum = 0
    )

    $BaseURL = "https://www.thebluealliance.com/api/v3"

    Write-Verbose "Preparing to download: $DataToDownload"

    $TBAURLs = @{
        AllEventsList = "$BaseURL/events/$Year"
        AllTeamsList  = "$BaseURL/teams/$Year/$PageNum/simple"
        TeamName      = "$BaseURL/team/$TeamKey/simple"
        EventOPR      = "$BaseURL/event/$EventKey/oprs"
        EventCOPR     = "$BaseURL/event/$EventKey/coprs"
        TeamMatch     = "$BaseURL/team/$TeamKey/event/$EventKey/matches/simple"
        EventRanking   = "$Baseurl/event/$EventKey/rankings"
    }

    if (-not $TBAURLs.ContainsKey($DataToDownload)) {
        throw "Invalid DataToDownload value: '$DataToDownload'. Valid options are: $($TBAURLs.Keys -join ', ')"
    }

    try {
        Write-Verbose "Retrieving TBA headers..."
        $TBAHeaders = Get-TBAHeader -ErrorAction Stop
        Write-Verbose "Headers retrieved successfully."
    }
    catch {
        throw "Failed to retrieve TBA headers: $_"
    }

    try {
        $Uri = $TBAURLs[$DataToDownload]
        Write-Verbose "Sending request to URI: $Uri"

        $Response = Invoke-WebRequest -Uri $Uri -Headers $TBAHeaders -AllowInsecureRedirect -ErrorAction Stop

        if ($Response.StatusCode -ne 200 -or -not $Response.Content) {
            throw "Unexpected response from TBA API. Status Code: $($Response.StatusCode)"
        }

        $Response.Content
    }
    catch {
        throw "Error retrieving TBA data: $_"
    }
}