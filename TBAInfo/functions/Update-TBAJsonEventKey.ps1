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