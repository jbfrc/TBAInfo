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