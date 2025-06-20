function Get-TBAEventTeamList {
    <#
        .SYNOPSIS
            Retrieve a list of teams participating in a specific event and returns
            basic information about the team.

        .DESCRIPTION
            This function queries The Blue Alliance (TBA) API to retrieve a list of all teams
            registered for a specific FIRST Robotics Competition (FRC) event, identified by its event key.
            It returns a collection of PowerShell custom objects, each representing a team with
            relevant details such as team number, nickname, location, rookie year, and website.

            The function requires a valid TBA API key, which should be provided via the Get-TBAHeader
            helper function. The event key can be passed as a parameter or retrieved dynamically
            using the Get-TBAJsonEventKey function.

            This is useful for scouting, event planning, or data analysis related to FRC events.

        .PARAMETER EventKey
            The event key (e.g., "2025ohcl") representing the specific FRC event to query.

        .EXAMPLE
            Get-TBAEventTeamList -EventKey "2025ohcl"
            TeamKey    : frc4611
            TeamNumber : 4611
            Nickname   : OZone
            City       : Delaware
            StateProv  : Ohio
            Country    : USA
            PostalCode : 43035
            RookieYear : 2013
            Website    : http:///www.olentangyfrc.org

            Retrieves and displays a list of teams attending the 2025 Cleveland, OH regional.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: June 1, 2025
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param(
        [string]$EventKey = $(Get-TBAJsonEventKey)
    )

    $EventTeamURL = "$BaseURL/event/$EventKey/teams"
    Write-Verbose "Event Team URL: $EventTeamURL"

    try {
        Write-Verbose "Attempting to retrieve TBA headers..."
        $TBAHeaders = Get-TBAHeader -ErrorAction Stop
        Write-Verbose "Successfully retrieved TBA headers."
    }
    catch {
        Write-Verbose "Failed to retrieve TBA headers."
        throw "Unable to generate TBA headers"
    }

    try {
        Write-Verbose "Sending request to TBA API..."
        $InvokeWebRequestParams = @{
            Uri = $EventTeamURL
            Headers = $TBAHeaders
            UseBasicParsing = $true
            AllowInsecureRedirect = $true
            ErrorAction = "Stop"
        }

        $TBAResponse = Invoke-WebRequest @InvokeWebRequestParams
        Write-Verbose "Received HTTP status code: $($TBAResponse.StatusCode)"

        if ($TBAResponse.StatusCode -ne 200) {
            Write-Verbose "Unexpected status code received: $($TBAResponse.StatusCode)"
            throw "Unexpected HTTP status code: $($TBAResponse.StatusCode)"
        }

        Write-Verbose "Parsing JSON response..."
        $EventTeams = $TBAResponse.Content | ConvertFrom-Json -ErrorAction Stop
        Write-Verbose "Successfully parsed team data. Total teams retrieved: $($EventTeams.Count)"

        $EventTeams = $EventTeams | Sort-Object -Property team_number
        $EventTeams | ForEach-Object {
            Write-Verbose "Processing team: $($_.team_number) - $($_.nickname)"
            [PSCustomObject]@{
                TeamKey    = $_.key
                TeamNumber = $_.team_number
                Nickname   = $_.nickname
                City       = $_.city
                StateProv  = $_.state_prov
                Country    = $_.country
                PostalCode = $_.postal_code
                RookieYear = $_.rookie_year
                Website    = $_.website
            }
        }
    }
    catch {
        throw "Failed to retrieve team information: $_"
    }
}