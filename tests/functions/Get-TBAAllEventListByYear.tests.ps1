BeforeAll {
    Import-Module TBAInfo -Force
}

Describe "Get-TBAAllEventListByYear" {
    Context "Test Cases that Should Work" {
        It "Should not thrown an error" {
            {Get-TBAAllEventListByYear -ErrorAction Stop} |
                Should -Not -Throw
        }
    }

    Context "Test Cases that Should Cause Problems" {

    }
}