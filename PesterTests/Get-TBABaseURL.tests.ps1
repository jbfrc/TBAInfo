Describe "Get-TBABaseURL" {
    Context "Test Cases That Should Work" {
        Import-Module TBAInfo -Force

        InModuleScope TBAInfo {
            It "Verify no errors are thrown" {
                { Get-TBABaseURL -ErrorAction Stop } | Should -Not -Throw
            }

            It "Returns the expected base URL" {
                Get-TBABaseURL | Should -Be "https://www.thebluealliance.com/api/v3/"
            }

            It "Writes verbose output" {
                $VerboseOutput = Get-TBABaseURL -Verbose 4>&1
                $VerboseOutput.Message | Should -Contain "TBA Base URL:"
            }
        }
    }
}