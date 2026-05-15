BeforeAll {
    Import-Module TBAInfo -Force

    $TeamKey = "frc4611"
    $TeamName = "Ozone"
}

Describe "Get-TBATeamName" {
    Context "Test Cases That Should Work" {
        BeforeAll {
            Mock -CommandName Invoke-WebRequest -ModuleName TBAInfo -MockWith {
                @{
                    StatusCode = 200
                    Content = '{"nickname":"Ozone"}'
                }
            }
        }

        It "Should not throw an error" {
            { Get-TBATeamName -TeamKey $TeamKey -ErrorAction Stop } |
                Should -Not -Throw
        }

        It "Test using TeamKey parameter" {
            Get-TBATeamName -TeamKey $TeamKey |
                Should -Be $TeamName
        }

        It "Test positional parameter" {
            Get-TBATeamName $TeamKey |
                Should -Be $TeamName
        }

        It "Test with pipeline input" {
            "frc4611" | Get-TBATeamName |
                Should -Be "Ozone"
        }

        It "Test with verbose switch" {
            Get-TBATeamName frc4611 -Verbose |
                Should -Be "Ozone"
        }
    }

    Context "Test Cases That Should Cause Problems" {
        It "Test with bad status code" {
            Mock -CommandName Invoke-WebRequest -ModuleName TBAInfo -MockWith {
                @{
                    StatusCode = 404
                    Content = '{}'
                }
            }

            {Get-TBATeamName -TeamKey "frc4611" -ErrorAction Stop } |
                Should -Throw "*Error retrieving team information for 'frc4611'*"
        }

        It "Test null value for tean name" {
            Mock -CommandName Invoke-WebRequest -ModuleName TBAInfo -MockWith {
                @{
                    StatusCode = 200
                    Content = '{"nickname":"Unknown"}'
                }
            }

            Get-TBATeamName frc12345 |
                Should -Be "Unknown"
        }
    }

}