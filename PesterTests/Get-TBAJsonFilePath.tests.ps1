# To Do: Use Pester testdrive

BeforeAll {
    Import-Module TBAInfo -Force
}

Describe 'Get-TBAJsonFilePath' {
    Context 'Test Cases that Should Work' {
        BeforeAll {
            Mock -CommandName Get-Module -ModuleName TBAInfo -MockWith {
                [pscustomobject]@{
                    Name = "TBAConfig"
                    Path = 'C:\Modules\TBAInfo\TBAInfo.psm1'
                }
            }

            Mock -CommandName Test-Path -ModuleName TBAInfo -MockWith {
                return $true
            }

            $ExpectedPath = "C:\Modules\TBAInfo\TBA.json"
        }

        It "Should not Have any Errors" {
            { Get-TBAJsonFilePath -ErrorAction Stop } |
                Should -Not -Throw
        }

        It "TBAConfig module should be available" {
            Get-Module -ListAvailable TBAInfo | Should -Not -BeNullOrEmpty
        }

        It 'Should return the correct path to TBA.json' {
            Get-TBAJsonFilePath | Should -Be $ExpectedPath
        }

        It "Should return the correct path to TBA.json with -Verbose switch" {
            Get-TBAJsonFilePath -Verbose | Should -Be $ExpectedPath
        }
    }

    
    Context 'Test Cases if TBAInfo Module is not Found' {
        BeforeAll {
            Mock -CommandName Get-Module -ModuleName TBAInfo -MockWith { $null }
        }

        It 'Should throw an error about missing module' {
            { Get-TBAJsonFilePath -ErrorAction Stop } |
                Should -Throw #"*The TBAInfo module could not be found.*"
        }
    }

    Context "Test when TBA.json does not exist" {
        BeforeAll {
            Mock -CommandName Test-Path -ModuleName TBAInfo -MockWith {
                return $false
            }
        }

        It 'Should throw an error about missing TBA.json file' {
            { Get-TBAJsonFilePath -ErrorAction Stop} |
                Should -Throw #'*The TBA.json file was not found in the TBAInfo module directory.*'
        }
    }
}