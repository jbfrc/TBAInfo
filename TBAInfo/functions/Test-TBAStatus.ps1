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