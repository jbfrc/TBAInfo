BeforeAll {
    Import-Module TBAInfo -Force
}

Describe "Get-TBAAllTeamList" {
    Context "Parameter Validation" {
        BeforeAll {
            $script:MockCounter = 0
            Mock -CommandName Get-TBAData -ModuleName TBAInfo -MockWith {
                if ($script:MockCounter -eq 0) {
                    '{
                        "team_number": 1234,
                        "nickname": "Test Team",
                        "key": "frc1234",
                        "city": "Testville",
                        "state_prov": "TS",
                        "country": "Testland"
                    }'
                }
                else {
                    $null
                }
                $script:MockCounter++
                
            }
        }

        It 'Accepts a valid 4-digit year' {
            $script:MockCounter = 0
            { Get-TBAAllTeamList -Year '2025' -Verbose } | Should -Not -Throw
        }

        It 'Rejects a non-4-digit year' {
            $script:MockCounter = 0
            { Get-TBAAllTeamList -Year '20AB' } | Should -Throw
        }

        It 'Rejects a year out of range' {
            $script:MockCounter = 0
            { Get-TBAAllTeamList -Year '1800' } | Should -Throw
        }
    }

    Context 'API Response Handling' {
        BeforeAll {
            $script:MockCounter = 0
            Mock -CommandName Get-TBAData -ModuleName TBAInfo -MockWith {
                if ($script:MockCounter -eq 0) {
                    '{
                        "team_number": 1234,
                        "nickname": "Test Team",
                        "key": "frc1234",
                        "city": "Testville",
                        "state_prov": "TS",
                        "country": "Testland"
                    }'
                }
                else {
                    $null
                }
                $script:MockCounter++
                
            }
        }

        Mock -CommandName ConvertFrom-Json -MockWith {
            return @(
                @{
                    team_number = 1234
                    nickname    = 'Test Team'
                    key         = 'frc1234'
                    city        = 'Testville'
                    state_prov  = 'TS'
                    country     = 'Testland'
                }
            )
        }

        It 'Returns expected team object' {
            $result = Get-TBAAllTeamList -Year '2026' -Verbose
            $result | Should -Not -BeNullOrEmpty
            $result.team_number | Should -Be 1234
            $result.name        | Should -Be 'Test Team'
        }
    }
}
