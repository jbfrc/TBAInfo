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