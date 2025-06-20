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