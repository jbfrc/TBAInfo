BeforeAll {
    Import-Module TBAInfo -Force
}

Describe "Get-TBAEventRanking" {
    Context "Test Cases that Should Work" {
        It "Should not throw an error" {
            { Get-TBAEventRanking -ErrorAction Stop } |
                Should -Not -Throw
        }
    }
}