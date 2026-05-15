BeforeAll {
    $ModuleName = "TBAInfo"
    Import-Module $ModuleName -Force
}

Describe Test-TBAStatus {

    Context "Test Cases that Should Work with Mock Functions" {

    }

    Context "Test Cases that Should Cause Problems" {

    }

    Context "Testing without Mocking TBA Function Calls" {
        It "Should not throw error" {
            {Test-TBAStatus -ErrorAction Stop} |
                Should -Not -Throw
        }
    }
}