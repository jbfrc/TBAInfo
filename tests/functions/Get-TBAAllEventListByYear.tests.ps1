BeforeAll {
    Import-Module TBAInfo -Force

    $EventName = "Test Event"
    $EventKey = "2025test"
    $EventType = 0
    $EventTypeString = "Regional"
    $EventWeek = 5
}

Describe "Get-TBAAllEventListByYear" {
    Context "Test Cases that Should Work with Mock Functions" {
        BeforeAll {
            Mock -CommandName Get-TBAData -ModuleName TBAInfo -MockWith {
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
            { Get-TBAAllEventListByYear -ErrorAction Stop } |
                Should -Not -Throw
        }

        It "Should Return One Result" {
            (Get-TBAAllEventListByYear).Count |
                Should -Be 1
        }
    }

    Context "Test Cases that Should Cause Problems" {

    }

    Context "Testing without Mocking TBA Function Calls" {
        It "Should not throw an error" {
            { Get-TBAAllEventListByYear -ErrorAction Stop } |
                Should -Not -Throw
        }

        It "Verify Buckeye Regional is Found" {
            $Event = Get-TBAAllEventListByYear |
                        Where-Object {$_.event_name -eq "Buckeye Regional"}

            $Event.Count |
                Should -Be 1

            $Event.event_name |
                Should -Be "Buckeye Regional"
        }

        It "Verify Buckeye Regional is Week 6" {
            (Get-TBAAllEventListByYear | Where-Object {$_.event_name -eq "Buckeye Regional"}).event_week |
                Should -Be 6
        }

        It "Verify Finger Lakes Regional is Week 3" {
            (Get-TBAAllEventListByYear | Where-Object {$_.event_name -eq "Finger Lakes Regional"}).event_week |
                Should -Be 3
        }

        It "Verify Week 0 Event is Listed (IncludeWeek0 Switch Works)" {
            Get-TBAAllEventListByYear -IncludeWeek0 | Where-Object {$_.event_week -eq 0} |
                Should -Not -BeNullOrEmpty
        }

        It "Verify OffSeason Event is Listed (IncludeOffSeason Switch Works)" {
            Get-TBAAllEventListByYear -IncludeOffSeason | Where-Object {$_.event_week -eq "Offseason"} |
                Should -Not -BeNullOrEmpty
        }
    }
}