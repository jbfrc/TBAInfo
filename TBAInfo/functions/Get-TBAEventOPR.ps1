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