BeforeAll {
    $ModuleName = "TBAInfo"
    Import-Module $ModuleName -Force

    $EventName = "Test Event"
    $EventKey = "2025test"
    $EventType = 0
    $EventTypeString = "Regional"
    $EventWeek = 5

    $BuckeyeRegionalWeek = 3
}

Describe "Get-TBAAllEventList" {
    Context "Test Cases that Should Work with Mock Functions" {
        BeforeAll {
            Mock -CommandName Get-TBAData -ModuleName $ModuleName -MockWith {
                '{
                    "name": "Test Event",
                    "key": "2025Test",
                    "event_type": 0,
                    "event_type_string": "Regional",
                    "week": 5
                }'
            }
        }

        It "Should not throw an error" {
            { Get-TBAAllEventList -ErrorAction Stop } |
                Should -Not -Throw
        }

        It "Should Return One Result" {
            (Get-TBAAllEventList).Count |
                Should -Be 1
        }
    }

    Context "Test Cases that Should Cause Problems" {

    }

    Context "Testing without Mocking TBA Function Calls" {
        It "Should not throw an error" {
            { Get-TBAAllEventList -ErrorAction Stop } |
                Should -Not -Throw
        }

        It "Verify Buckeye Regional is Found" {
            $Event = Get-TBAAllEventList |
                        Where-Object {$_.event_name -eq "Buckeye Regional"}

            $Event.Count |
                Should -Be 1

            $Event.event_name |
                Should -Be "Buckeye Regional"
        }

        It "Verify Buckeye Regional is Week 6" {
            (Get-TBAAllEventList | Where-Object {$_.event_name -eq "Buckeye Regional"}).event_week |
                Should -Be $BuckeyeRegionalWeek
        }

        It "Verify Week 0 Event is Listed (IncludeWeek0 Switch Works)" {
            Get-TBAAllEventList -IncludeWeek0 | Where-Object {$_.event_week -eq "Preseason"} |
                Should -Not -BeNullOrEmpty
        }

        It "Verify OffSeason Event is Listed (IncludeOffSeason Switch Works)" {
            Get-TBAAllEventList -IncludeOffSeason | Where-Object {$_.event_week -eq "Offseason"} |
                Should -Not -BeNullOrEmpty
        }
    }
}