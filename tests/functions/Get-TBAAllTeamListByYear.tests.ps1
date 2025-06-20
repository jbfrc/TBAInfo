BeforeAll {
    Import-Module TBAInfo -Force
}

Describe 'Get-TBAAllTeamListByYear' {
    Context 'Parameter Validation' {
        BeforeAll {
            $script:MockCounter = 0
            Mock -CommandName Get-TBAData -ModuleName TBAInfo -MockWith {
                if ($script:MockCounter -eq 0) {
                    '{"team_number": 1234, "nickname": "Test Team", "key": "frc1234", "city": "Testville", "state_prov": "TS", "country": "Testland"}'
                }
                else {
                    $null
                }
                $script:MockCounter++
                
            }
        }

        It 'Accepts a valid 4-digit year' {
            $script:MockCounter = 0
            { Get-TBAAllTeamListByYear -Year '2025' -Verbose } | Should -Not -Throw
        }

        It 'Rejects a non-4-digit year' {
            $script:MockCounter = 0
            { Get-TBAAllTeamListByYear -Year '20AB' } | Should -Throw
        }

        It 'Rejects a year out of range' {
            $script:MockCounter = 0
            { Get-TBAAllTeamListByYear -Year '1800' } | Should -Throw
        }
    }

    Context 'API Response Handling' {
        BeforeAll {
            $script:MockCounter = 0
            Mock -CommandName Get-TBAData -ModuleName TBAInfo -MockWith {
                if ($script:MockCounter -eq 0) {
                    '{"team_number": 1234, "nickname": "Test Team", "key": "frc1234", "city": "Testville", "state_prov": "TS", "country": "Testland"}'
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
            $result = Get-TBAAllTeamListByYear -Year '2025' -Verbose
            $result | Should -Not -BeNullOrEmpty
            $result.team_number | Should -Be 1234
            $result.name        | Should -Be 'Test Team'
        }
    }

    <#
    Context 'Retry Logic' {
        $callCount = 0

        Mock -CommandName Get-TBAData -MockWith {
            $script:callCount++
            if ($script:callCount -lt 2) {
                throw "Simulated failure"
            }
            return '{"team_number": 9999, "nickname": "Retry Team", "key": "frc9999", "city": "Retryville", "state_prov": "RT", "country": "Retryland"}'
        }

        Mock -CommandName ConvertFrom-Json -MockWith {
            return @(
                @{
                    team_number = 9999
                    nickname    = 'Retry Team'
                    key         = 'frc9999'
                    city        = 'Retryville'
                    state_prov  = 'RT'
                    country     = 'Retryland'
                }
            )
        }

        It 'Retries on failure and eventually succeeds' {
            $script:callCount = 0
            $result = Get-TBAAllTeamListByYear -Year '2024' -Verbose
            $result.team_number | Should -Be 9999
            $script:callCount | Should -Be 2
        }
    }
        #>
}
