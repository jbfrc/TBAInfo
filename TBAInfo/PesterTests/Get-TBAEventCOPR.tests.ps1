BeforeAll {
    $ModuleName = "TBAInfo"
    Import-Module $ModuleName -Force
}

Describe Get-TBAEventCOPR {

    Context "Test Cases that Should Work with Mock Functions" {

    }

    Context "Test Cases that Should Cause Problems" {

    }

    Context "Testing without Mocking TBA Function Calls" {
        It "Should not throw error" {
            {Get-TBAEventCOPR -ErrorAction Stop} |
                Should -Not -Throw
        }
    }
}