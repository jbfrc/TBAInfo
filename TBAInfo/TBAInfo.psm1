$BaseURL = "https://www.thebluealliance.com/api/v3/"

function Get-TBAAllEventListByYear {
    <#
        .SYNOPSIS
            Fetches a list of FIRST Robotics Competition events for a given year from The Blue Alliance (TBA) API.

        .DESCRIPTION
            This function retrieves all events for a specified year using The Blue Alliance API.
            It allows optional inclusion of preseason (week 0) and offseason events. The results are
            returned as a list of custom objects sorted by event week.

        .PARAMETER Year
            The year for which to fetch events. Defaults to the current year.

        .PARAMETER IncludeWeek0
            If specified, includes preseason (week 0) events.

        .PARAMETER IncludeOffseason
            If specified, includes offseason events.

        .OUTPUTS
            A sorted list of PowerShell custom objects, each representing an event with the following properties:
            - event_name
            - event_key
            - event_type
            - event_type_string
            - event_week

        .EXAMPLE
            Get-TBAAllEventListByYear -Year 2024 -IncludeWeek0 -Verbose

            Fetches all 2024 events including preseason, with verbose output.

        .NOTES
            Written By: Jeff Brusoe
            Last Updated: August 3, 2025
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [string]$Year = (Get-Date).Year,
        [switch]$IncludeWeek0,
        [switch]$IncludeOffSeason
    )

    try {
        Write-Verbose "Pulling TBA Data"

        $GetTBADataParams = @{
            DataToDownload = "AllEventsList"
            Year = $Year
            ErrorAction = "Stop"
        }
        $FRCEvents = Get-TBAData @GetTBADataParams |
                        ConvertFrom-Json

        $FRCEvents = $FRCEvents |
                        Sort-Object { if ($null -eq $_.week) {7} else { $_.week} }
    }
    catch {
        throw "TBA Request failed: $_"
    }

    Write-Verbose "Looping through TBA results"
    foreach ($FRCEvent in $FRCEvents) {
        $IncludeEvent = $false
        $Week = $null

        if ($null -ne $FRCEvent.week) {
            $IncludeEvent = $true
            $Week = $FRCEvent.week + 1
        }
        elseif ($FRCEvent.event_type_string -eq "Preseason" -AND $IncludeWeek0) {
            $IncludeEvent = $true
            $Week = 0
        }
        elseif ($FRCEvent.event_type_string -eq "Offseason" -AND $IncludeOffseason) {
            $IncludeEvent = $true
            $Week = "Offseason"
        }
        elseif ($FRCEvent.event_type_string -eq "Championship Division" -OR
                $FRCEvent.event_type_string -eq "Championship Finals") {
            $IncludeEvent = $true
            $Week = 8
        }

        if ($IncludeEvent) {
            [PSCustomObject]@{
                event_name = $FRCEvent.name
                event_key  = $FRCEvent.key
                event_type = $FRCEvent.event_type
                event_type_string = $FRCEvent.event_type_string
                event_week = $Week
            }
        }
    }
}

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

function Get-TBAEventCOPR {
    <#
        .SYNOPSIS
            Retrieves Component OPR (COPR) data for a specific FRC event from The Blue Alliance API.

        .DESCRIPTION
            This function queries The Blue Alliance (TBA) API for Component Offensive Power Ratings (COPR)
            for a given event. It returns a list of teams with their calculated COPR values such as
            L4 Coral Count or Total Algae Count (from 2025) sorted by team number.

        .PARAMETER EventKey
            The event key used to identify the FRC event (e.g., "2025nyro").
            If not provided, the function attempts to retrieve it using Get-TBAJsonEventKey.

        .EXAMPLE
            Get-TBAEventCOPR -EventKey "2025nyro"

            Retrieves COPR data from the 2025 Finger Lakes Regional and returns a list of teams with their
            component OPR values.

        .EXAMPLE
            "2024onwat" | Get-TBAEventCOPR

            Uses pipeline input to retrieve COPR data for the 2024 Waterloo event.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: June 15, 2025
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidatePattern('(?i)^\d{4}[a-z0-9]+$')]
        [string]$EventKey = $(Get-TBAJsonEventKey)
    )

    process {
        Write-Verbose "Using Event Key: $EventKey"

        try {
            Write-Verbose "Retrieving OPR data from The Blue Alliance..."
            $GetTBADataParams = @{
                DataToDownload = "EventCOPR"
                EventKey       = $EventKey
                ErrorAction    = "Stop"
            }
            $AllCOPRInfo = Get-TBAData @GetTBADataParams |
                           ConvertFrom-Json -ErrorAction Stop

            Write-Verbose "Extracting team statistics..."

            # Get all metric names (e.g., oprs, dprs, ccwms)
            $MetricNames = $AllCOPRInfo.PSObject.Properties.Name

            # Get all team keys from the first metric
            $TeamKeys = $AllCOPRInfo.$($MetricNames[0]).PSObject.Properties.Name

            $COPRInfo = foreach ($TeamKey in $TeamKeys) {
                $TeamData = [ordered]@{
                    TeamNumber = [int]($TeamKey -replace "frc","")
                }

                foreach ($Metric in $MetricNames) {
                    $TeamData[$Metric] = $AllCOPRInfo.$Metric.$TeamKey
                }

                [PSCustomObject]$TeamData
            }

            $COPRInfo | Sort-Object -Property TeamNumber
        }
        catch {
            throw "Failed to retrieve team information for event '$EventKey': $_"
        }
    }
}

function Get-TBAEventOPR {
<#
    .SYNOPSIS
        Retrieves Offensive Power Rating (OPR), Defensive Power Rating (DPR), and Calculated Contribution
        to Winning Margin (CCWM) for all teams at a specified FIRST Robotics Competition (FRC) event.

    .DESCRIPTION
        This function queries The Blue Alliance (TBA) API for a given event key and returns a list of
        team statistics including OPR, DPR, and CCWM. The data is sorted by team number.

    .PARAMETER EventKey
        The event key for the FRC event (e.g., "2025ohcl").
        If not provided, the function attempts to retrieve it using Get-TBAJsonEventKey.

    .OUTPUTS
        [PSCustomObject]
        Returns a list of custom objects with the following properties:
        - TeamNumber
        - OPR
        - DPR
        - CCWM

    .EXAMPLE
        Get-TBAEventOPR -EventKey "2025ohcl"

    .EXAMPLE
        "2025ohcl" | Get-TBAEventOPR

    .NOTES
        Written by: Jeff Brusoe
        Last Updated: June 14, 2025
#>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidatePattern('(?i)^\d{4}[a-z0-9]+$')]  # Case-insensitive pattern
        [string]$EventKey = $(Get-TBAJsonEventKey)
    )

    begin {
        <#
        if (-not $PSBoundParameters.ContainsKey('EventKey')) {
            Write-Verbose "No EventKey provided. Attempting to retrieve default event key..."
            $EventKey = Get-TBAJsonEventKey
        }
        #>
    }

    process {
        Write-Verbose "Using Event Key: $EventKey"

        try {
            Write-Verbose "Retrieving OPR data from The Blue Alliance..."
            $GetTBADataParams = @{
                DataToDownload = "EventOPR"
                EventKey = $EventKey
                ErrorAction = "Stop"
            }
            $AllOPRInfo = Get-TBAData @GetTBADataParams |
                            ConvertFrom-Json -ErrorAction Stop

            Write-Verbose "Extracting team statistics..."
            $TeamKeys = $AllOPRInfo.oprs.PSObject.Properties.Name

            $OPRInfo = foreach ($TeamKey in $TeamKeys) {
                [PSCustomObject]@{
                    TeamNumber = [int]($TeamKey -replace "frc","")
                    OPR        = [math]::Round($AllOPRInfo.oprs.$TeamKey, 2)
                    DPR        = [math]::Round($AllOPRInfo.dprs.$TeamKey, 2)
                    CCWM       = [math]::Round($AllOPRInfo.ccwms.$TeamKey, 2)
                }
            }

            $OPRInfo | Sort-Object -Property TeamNumber
        }
        catch {
            throw "Failed to retrieve team information for event '$EventKey': $_"
        }
    }
}


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

function Get-TBAJsonAPIKey {
    <#
        .SYNOPSIS
            Retrieves the API key from a TBA JSON configuration file.

        .DESCRIPTION
            This function reads a JSON configuration file and extracts the value of the `api_key` property.
            It includes error handling for missing files, invalid JSON, and missing keys.

            This function assumes that the JSON file contains an `api_key` field at the root level.

        .PARAMETER JsonFilePath
            The full path to the JSON configuration file. If not specified, the function will use a default path
            as defined in the `Get-TBAJSONConfig` function.

        .OUTPUTS
            System.String

        .EXAMPLE
            Get-TBAJsonAPIKey -JsonFilePath "C:\Configs\tba_config.json"
            Returns the API key from the specified JSON file.

        .EXAMPLE
            Get-TBAJsonAPIKey
            Returns the API key using the default JSON file path.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 25, 2025
    #>

    [OutputType([string])]
    [CmdletBinding()]
    param (
        [string]$JsonFilePath = $(Get-TBAJsonFilePath)
    )

    try {
        Write-Verbose "Reading TBA Config File"
        $TBAConfig = Get-TBAJsonConfig -JsonFilePath $JsonFilePath -ErrorAction Stop

        if (-not $TBAConfig.api_key) {
            throw "The 'api_key' property was not found in the JSON configuration."
        }
        else {
            Write-Verbose "API Key has been read"
        }

        Write-Output $TBAConfig.api_key
    }
    catch {
        Write-Error "Failed to retrieve API key: $_"
    }
}

function Get-TBAJsonConfig {
    <#
        .SYNOPSIS
            Reads a JSON file and extracts the values of 'api_key', 'team_key', and 'event_key'.

        .DESCRIPTION
            This function reads a JSON file (defaulting to 'TBA.json' in the same directory as the 'TBAInfo' module),
            parses its contents, and returns the values of the 'api_key', 'team_key', and 'event_key' fields if they exist.
            It includes error handling for missing files and missing fields.

        .PARAMETER JsonFilePath
            The full path to the JSON file that contains the required fields.
            If not specified, the function attempts to locate 'TBA.json' in the TBAInfo module directory.

        .OUTPUTS
            PSCustomObject
            Returns an object with 'api_key', 'team_key', and 'event_key' properties.

        .EXAMPLE
            Get-TBAJSONConfig
            team_key event_key api_key
            -------- --------- -------
            frc4611  2025ohcl  <MyAPIKey>

            (Assumes TBA.json is in the TBAInfo module directory)

        .EXAMPLE
            Get-TBAJSONConfig -JsonFilePath "C:\data\TBA.json"
            team_key event_key api_key
            -------- --------- -------
            frc4611  2025ohcl  <MyAPIKey>

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 25, 2025

            To Do:
            1. Parameter Validation
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [string]$JsonFilePath = $(Get-TBAJsonFilePath)
    )

    Write-Verbose "Path to JSON File: $JsonFilePath"

    try {
        $GetContentParams = @{
            Path = $JsonFilePath
            Raw = $true
            ErrorAction = "Stop"
        }
        $JsonContent = Get-Content @GetContentParams | ConvertFrom-Json

        [PSCustomObject]@{
            team_key  = $JsonContent.team_key
            event_key = $JsonContent.event_key
            api_key   = $JsonContent.api_key
        }
    } catch {
        throw "Failed to read or parse the JSON file"
    }
}

function Get-TBAJsonEventKey {
    <#
        .SYNOPSIS
            Retrieves the event key (such as '2025miket') from the TBA JSON configuration file.

        .DESCRIPTION
            This function reads a JSON configuration file and extracts the value of the `event_key` property.
            It includes error handling for invalid JSON and missing keys.

            This function assumes that the JSON file contains an `event_key` field at the root level.

        .PARAMETER JsonFilePath
            The full path to the JSON configuration file. If not specified, the function will use a default path
            as defined in the `Get-TBAJSONConfig` function.

        .OUTPUTS
            System.String

        .EXAMPLE
            Get-TBAJsonEventKey -JsonFilePath "C:\Configs\tba_config.json"

            Returns the event key from the specified JSON file.

        .EXAMPLE
            Get-TBAJsonEventKey

            Returns the event key using the default JSON file path.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 30, 2025
    #>

    [OutputType([string])]
    [CmdletBinding()]
    param (
        [string]$JsonFilePath = $(Get-TBAJsonFilePath)
    )

    try {
        Write-Verbose "Retrieving configuration using Get-TBAJSONConfig..."
        $config = Get-TBAJSONConfig -JsonFilePath $JsonFilePath

        Write-Verbose "Checking for 'event_key' in the configuration..."
        if (-not $config.event_key) {
            throw "The 'event_key' property was not found in the JSON configuration."
        }

        Write-Verbose "'event_key' found. Returning value: $($config.event_key)"
        Write-Output $config.event_key
    }
    catch {
        Write-Error "Failed to retrieve event key: $_"
    }
}

function Get-TBAJsonFilePath {
    <#
        .SYNOPSIS
            Retrieves the full path to the TBA.json file located in the TBAInfo module directory.

        .DESCRIPTION
            This function locates the TBAInfo module on the system and constructs the full path
            to the TBA.json file assumed to be in the same directory.

        .OUTPUTS
            System.String
            Returns the full file path to TBA.json if the module is found.

        .EXAMPLE
            PS> Get-TBAJsonFilePath
            C:\Program Files\WindowsPowerShell\Modules\TBAInfo\TBA.json

        .NOTES
            Written By: Jeff Brusoe
            Last Updated: May 25, 2025
    #>

    [OutputType([string])]
    [CmdletBinding()]
    param (

    )

    try {
        $JsonConfigModule = Get-Module -ListAvailable TBAInfo -ErrorAction Stop
            | Select-Object -First 1

        if (-not $JsonConfigModule) {
            throw "The TBAInfo module could not be found."
        }
        else {
            Write-Verbose "Found TBAInfo module"
        }

        Write-Verbose "Determining path to JSON file"
        $JoinPathParams = @{
            Path = $(Split-Path -Path $JsonConfigModule.Path -Parent -ErrorAction Stop)
            ChildPath = "TBA.json"
            ErrorAction = "Stop"
        }
        $JsonFilePath = Join-Path @JoinPathParams

        if (-not (Test-Path -Path $JsonFilePath)) {
            throw [System.IO.FileNotFoundException]::new("The TBA.json file was not found in the TBAInfo module directory.")
        }
        else {
            Write-Verbose "TBA.json was found"
        }

        Write-Verbose "JSON File Path $JsonFilePath"
        Write-Output $JsonFilePath
    }
    catch {
        throw "Error in Get-TBAJsonFilePath"
    }
}

function Get-TBAJsonTeamKey {
    <#
        .SYNOPSIS
            Retrieves the team key (such as 'frc4611') from the TBA JSON configuration file.

        .DESCRIPTION
            This function reads a JSON configuration file and extracts the value of the `team_key` property.
            It includes error handling for invalid JSON and missing keys.

            This function assumes that the JSON file contains a `team_key` field at the root level.

        .PARAMETER JsonFilePath
            The full path to the JSON configuration file. If not specified, the function will use a default path
            as defined in the `Get-TBAJSONConfig` function.

        .OUTPUTS
            System.String

        .EXAMPLE
            Get-TBAJSONTeamKey -JsonFilePath "C:\Configs\tba_config.json"
            Returns the team key from the specified JSON file.

        .EXAMPLE
            Get-TBAJSONTeamKey
            Returns the team key using the default JSON file path.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 25, 2025
    #>

    [OutputType([string])]
    [CmdletBinding()]
    param (
        [string]$JsonFilePath = $(Get-TBAJsonFilePath)
    )

    try {
        Write-Verbose "Retrieving configuration using Get-TBAJSONConfig..."
        $config = Get-TBAJSONConfig -JsonFilePath $JsonFilePath

        Write-Verbose "Checking for 'team_key' in the configuration..."
        if (-not $config.team_key) {
            throw "The 'team_key' property was not found in the JSON configuration."
        }

        Write-Verbose "'team_key' found. Returning value: $($config.team_key)"
        Write-Output $config.team_key
    }
    catch {
        Write-Error "Failed to retrieve team key: $_"
    }
}

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

function New-TBAConfigFile {
    <#
    .SYNOPSIS
    Creates a JSON configuration file for The Blue Alliance API.

    .DESCRIPTION
    This function creates a JSON file named 'config.json' containing the TBA API key, event key, and team key.
    Users can either provide these values as parameters or be prompted to enter them interactively.

    .PARAMETER ApiKey
    The TBA API key used for authentication.

    .PARAMETER EventKey
    The event key (e.g., "2025ohcl") for the FRC event.

    .PARAMETER TeamKey
    The team key (e.g., "frc254") for the FRC team.

    .EXAMPLE
    New-TBAConfigFile

    Prompts the user to enter API key, event key, and team key, then saves them to 'config.json'.

    .EXAMPLE
    New-TBAConfigFile -ApiKey "abc123" -EventKey "2025ohcl" -TeamKey "frc254"

    Saves the provided values directly to 'config.json' without prompting.

    .NOTES
    Written By: Jeff Brusoe  
    Last Updated: June 15, 2025
    #>

    [CmdletBinding()]
    param (
        [string]$ApiKey,
        [string]$EventKey,
        [string]$TeamKey
    )

    if (-not $ApiKey)   { $ApiKey   = Read-Host "Enter your TBA API key" }
    if (-not $EventKey) { $EventKey = Read-Host "Enter your Event key (e.g., 2025ohcl)" }
    if (-not $TeamKey)  { $TeamKey  = Read-Host "Enter your Team key (e.g., frc254)" }

    $config = [PSCustomObject]@{
        api_key   = $ApiKey
        event_key = $EventKey
        team_key  = $TeamKey
    }

    $config | ConvertTo-Json -Depth 3 | Set-Content -Path "./config.json" -Encoding UTF8

    Write-Host "Configuration saved to config.json"
}

function Test-TBAStatus {
    <#
        .SYNOPSIS
            Tests the availability of The Blue Alliance (TBA) API service.

        .DESCRIPTION
            This function sends a request to the TBA API's `/status` endpoint
            using the base URL and headers provided by the `Get-TBAHeaders` function.
            It returns `$true` if the API responds with HTTP status code 200, indicating
            that the service is online and reachable. Otherwise, it returns `$false`.

        .OUTPUTS
            System.Boolean
            Returns `$true` if the TBA API is reachable and responding with status code 200;
            otherwise, returns `$false`.

        .EXAMPLE
            PS> Test-TBAStatus
            True

            This example checks the status of the TBA API and returns `True` if the service is up.

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 24, 2025
    #>

    [OutputType([bool])]
    [CmdletBinding()]
    param()

    $TestTBAURL = $BaseURL + "status"
    Write-Verbose "Constructed TBA status URL: $TestTBAURL"

    try {
        $TBAHeaders = Get-TBAHeader
        Write-Verbose "Retrieved headers for request: $($TBAHeaders | Out-String)"

        $TBARequest = Invoke-WebRequest -Uri $TestTBAURL -Headers $TBAHeaders -ErrorAction Stop
        Write-Verbose "Received response with status code: $($TBARequest.StatusCode)"

        if ($TBARequest.StatusCode -eq 200) {
            Write-Verbose "TBA API is online."
            Write-Output $true
        }
        else {
            Write-Warning "TBA API responded with unexpected status code: $($TBARequest.StatusCode)"
            Write-Output $false
        }
    }
    catch {
        Write-Error "Failed to reach TBA API: $_"
        Write-Output $false
    }
}

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

function Update-TBAJsonEventKey {
    <#
        .SYNOPSIS
            Updates the event_key field in a TBA JSON file.

        .DESCRIPTION
            This is a wrapper around Update-TBAJsonFields that simplifies updating
            just the event_key field. It includes error handling and supports pipeline input.

        .PARAMETER EventKey
            The new event key to set in the JSON file (e.g., '2025ohcl').

        .EXAMPLE
            Update-TBAJsonEventKey -EventKey "2025ohcl"

            Updates the event_key field in the JSON config file to 2025ohcl

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
        [string]$EventKey
    )

    process {
        try {
            Write-Verbose "Calling Update-TBAJsonFields to update event_key"
            Update-TBAJsonFields -EventKey $EventKey -ErrorAction Stop
            Write-Verbose "Successfully updated event key in JSON file"
        } catch {
            Write-Error "Failed to update event_key: $_"
        }
    }
}

function Update-TBAJsonTeamKey {
    <#
        .SYNOPSIS
            Updates the team_key field in a TBA JSON file.

        .DESCRIPTION
            This is a wrapper around Update-TBAJsonFields that simplifies updating
            just the team_key field. It includes validation (must start with 'frc' followed by digits or
            just the team number) as well as error handling.

        .PARAMETER TeamKey
            The new team key to set in the JSON file. Must start with 'frc' followed by digits (e.g., 'frc1234').

        .EXAMPLE
            Update-TBAJsonTeamKey -TeamKey "frc4611"
            Update-TBAJsonTeamKey -TeamKey 4611

            Both will correctly update the team_key field in the JSON config file.

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
        [ValidatePattern("^frc\d+$|^\d+$")]
        [string]$TeamKey
    )

    try {
        if ($TeamKey -match "^\d+$") {
            $TeamKey = "frc$TeamKey"
        } 

        Write-Verbose "Calling Update-TBAJsonFields to update team_key"
        Update-TBAJsonFields -TeamKey $TeamKey -ErrorAction Stop
        Write-Verbose "Successfully updated team key in JSON file"
    }
    catch {
        Write-Error "Failed to update team_key: $_"
    }
}

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

function Get-TBAHeader {
    <#
        .SYNOPSIS
            Constructs the HTTP headers required for accessing The Blue Alliance (TBA) API.

        .DESCRIPTION
            This function generates a hashtable of HTTP headers used for authenticating and
            interacting with the TBA API. It retrieves the API key using the Get-TBAAPIKeyFromJSON function
            and includes a placeholder for the 'If-Modified-Since' header.

        .OUTPUTS
            System.Collections.Hashtable
            Returns a hashtable containing the required HTTP headers for TBA API requests.

        .EXAMPLE
            Get-TBAHeader
            Returns a hashtable like:
            @{
                'X-TBA-Auth-Key' = 'your-api-key'
                'Last-Modified' = 'If-Modified-Since'
            }

            This is based on this documentation - https://www.thebluealliance.com/apidocs

        .NOTES
            Written by: Jeff Brusoe
            Last Updated: May 25, 2025
    #>

    [OutputType([hashtable])]
    [CmdletBinding()]
    param()

    try {
        Write-Verbose "Determining TBA Headers"

        $TBAHeaders = @{
            'X-TBA-Auth-Key' = $(Get-TBAJsonAPIKey -ErrorAction Stop)
            'Last-Modified'  = 'If-Modified-Since'
        }

        Write-Verbose "Successfully Generated TBA Headers"
    }
    catch {
        throw "Unable to get API key"
    }

    Write-Output $TBAHeaders
}

function Invoke-TBARetry {
    <#
    .SYNOPSIS
        Executes a script block with retry logic for transient failures.

    .DESCRIPTION
        This function attempts to execute a script block. If the script block throws an exception,
        it will retry the execution up to a specified number of times, with a delay between each attempt.
        This is useful for handling transient errors such as network timeouts or temporary service unavailability.

    .PARAMETER ScriptBlock
        The script block to execute. This should be the code that might fail intermittently.

    .PARAMETER MaxRetries
        Maximum number of retry attempts. Default is 3.

    .PARAMETER DelaySeconds
        Delay between retries in seconds. Default is 2.

    .EXAMPLE
        Invoke-TBARetry -ScriptBlock {
            Invoke-WebRequest -Uri "https://example.com/api/data"
        }

        This example attempts to fetch data from a web API. If the request fails, it will retry up to 3 times
        with a 2-second delay between attempts.

    .EXAMPLE
        Invoke-TBARetry -ScriptBlock {
            Get-Content "\\NetworkShare\file.txt"
        } -MaxRetries 5 -DelaySeconds 10

        This example tries to read a file from a network share. It will retry up to 5 times with a 10-second delay
        between each attempt in case of transient network issues.

    .NOTES
        Author: Your Name
        Created: 2025-06-18
    #>
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2
    )

    $RetryCount = 0

    while ($RetryCount -lt $MaxRetries) {
        try {
            return & $ScriptBlock
        } catch {
            Write-Warning "Attempt $($RetryCount + 1) failed: $_"
            $RetryCount++
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    Write-Verbose "Exceeded maximum retry attempts."
    Write-Output $null
}

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