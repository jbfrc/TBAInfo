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