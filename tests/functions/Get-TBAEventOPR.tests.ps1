BeforeAll {
    Import-Module TBAInfo -Force
}

Describe "Get-TBAEventOPR" {
    Context "Test Cases that Should Work" {
        BeforeAll {
            $OzoneOPR = "84.12"
            Mock -CommandName Invoke-WebRequest -ModuleName TBAInfo -MockWith {
                @{
                    StatusCode = 200
                    Content = '{
                        "ccwms": {
                            "frc4611": 51.811,
                            "frc48": 25.511,
                        },
                        "dprs": {
                            "frc4611": 32.301,
                            "frc48": 36.841,
                        },
                        "oprs": {
                            "frc4611": 84.121,
                            "frc48": 62.341,
                        }
                    }'

                }
            }
        }

        It "Verify no errors are thrown" {
            {Get-TBAEventOPR -Eventkey "2025ohcl" -ErrorAction Stop } |
                Should -Not -Throw
        }
        
        It "Verify Ozone OPR is correct" {
            (Get-TBAEventOPR -EventKey "2025ohcl" | Where-Object {$_.TeamNumber -eq 4611}).OPR |
                Should -Be $OzoneOPR
        }

        It "Verify team 48 is first in output list" {
            # Verifies that the output order is correct
            (Get-TBAEventOPR -EventKey "2025ohcl")[0].TeamNumber |
                Should -Be 48
        }
    }

    Context "Test Cases that Should Cause Problems" {
        
    }
}