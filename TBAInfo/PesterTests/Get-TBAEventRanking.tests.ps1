BeforeAll {
    Import-Module TBAInfo -Force
}

Describe Get-TBAEventRanking {

    Context "Test Cases that Should Work with Mock Functions" {

    }

    Context "Test Cases that Should Cause Problems" {

    }

    Context "Testing without Mocking TBA Function Calls" {
        It "Should not throw error" {
            {Get-TBAEventRanking -ErrorAction Stop} |
                Should -Not -Throw
        }
    }
}