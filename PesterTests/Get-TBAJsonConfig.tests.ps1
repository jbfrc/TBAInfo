BeforeAll {
    Import-Module TBAInfo -Force
}

Describe "Get-TBAJsonConfig" {
    Context "Test Cases that Should Work" {
        BeforeAll {
            $JsonPath = "TestDrive:\TBA.json"
            $TeamKey = "frc4611"
            $EventKey = "2025ohcl"
            $APIKey = "MyAPIKey"

            $TBAJson = @{
                "team_key" = "frc4611"
                "event_key" = "2025ohcl"
                "api_key" = "MyAPIKey"
            }

            $JsonTestFile = $TBAJson |
                            ConvertTo-Json |
                            Out-File -FilePath $JsonPath
            
            Mock -CommandName Get-TBAJsonFilePath -ModuleName TBAInfo -MockWith {
                return $JsonPath
            }
        }

        It "Should not throw an error" {
            { Get-TBAJsonConfig -ErrorAction Stop } |
                Should -Not -Throw
        }

        It "Verify correct value for team_key" {
            (Get-TBAJsonConfig)."team_key" |
                Should -Be $TeamKey
        }

        It "Verify correct value for event_key" {
            (Get-TBAJsonConfig)."event_key" |
                Should -Be $EventKey
        }

        It "Verify correct value for api_key" {
            (Get-TBAJsonConfig)."api_key" |
                Should -Be $APIKey
        }
    }

    Context "Test Cases that Should Throw an Error" {
        BeforeAll {
            
        }
    }
}