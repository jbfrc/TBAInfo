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