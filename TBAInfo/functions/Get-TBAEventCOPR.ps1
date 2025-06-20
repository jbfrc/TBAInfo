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