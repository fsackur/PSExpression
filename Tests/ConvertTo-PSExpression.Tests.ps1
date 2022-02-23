
BeforeDiscovery {

    $PrimitiveTestCases = @(
        @{Name = '$null';               InputObject = $null;                Expected = '$null'},
        @{Name = '$true';               InputObject = $true;                Expected = '$true'},
        @{Name = '$false';              InputObject = $false;               Expected = '$false'},
        @{Name = "[char]'c'";           InputObject = [char]'c';            Expected = 'c'},
        @{Name = '0';                   InputObject = 0;                    Expected = '0'},
        @{Name = '1';                   InputObject = 1;                    Expected = '1'},
        @{Name = '-1';                  InputObject = -1;                   Expected = '-1'},
        @{Name = '0.5';                 InputObject = 0.5;                  Expected = '0.5'},
        @{Name = '-0.5';                InputObject = -0.5;                 Expected = '-0.5'},
        @{Name = '[uint16]::MinValue';  InputObject = [uint16]::MinValue;   Expected = '0'},
        @{Name = '[uint16]::MaxValue';  InputObject = [uint16]::MaxValue;   Expected = '65535'},
        @{Name = '[long]::MinValue';    InputObject = [long]::MinValue;     Expected = '-9223372036854775808'},
        @{Name = '[long]::MaxValue';    InputObject = [long]::MaxValue;     Expected = '9223372036854775807'},
        @{Name = '[int]::MinValue';     InputObject = [int]::MinValue;      Expected = '-2147483648'},
        @{Name = '[int]::MaxValue';     InputObject = [int]::MaxValue;      Expected = '2147483647'},

        # Precision is system-dependant
        @{Name = '1/3';                 InputObject = 1/3;                  Expected = (1/3).ToString()},
        @{Name = '[float]::MinValue';   InputObject = [float]::MinValue;    Expected = [float]::MinValue.ToString()},
        @{Name = '[float]::MaxValue';   InputObject = [float]::MaxValue;    Expected = [float]::MaxValue.ToString()},
        @{Name = '[double]::MinValue';  InputObject = [double]::MinValue;   Expected = [double]::MinValue.ToString()},
        @{Name = '[double]::MaxValue';  InputObject = [double]::MaxValue;   Expected = [double]::MaxValue.ToString()},
        @{Name = '[Math]::PI';          InputObject = [Math]::PI;           Expected = [Math]::PI.ToString()}
    )

    $PrimitiveErrorCases = (
        @{Name = '[float]::NaN';                InputObject = [float]::NaN;                 ExpectedError = "value 'NaN' of type System.Single"},
        @{Name = '[double]::NaN';               InputObject = [double]::NaN;                ExpectedError = "value 'NaN' of type System.Double"},
        @{Name = '[float]::NegativeInfinity';   InputObject = [float]::NegativeInfinity;    ExpectedError = "value '-∞' of type System.Single"},
        @{Name = '[double]::PositiveInfinity';  InputObject = [double]::PositiveInfinity;   ExpectedError = "value '∞' of type System.Double"}
    )

    $PartyTime = [datetime]::new(1999, 12, 31, 23, 59, 59, 999, 'Utc')
    $ObjectTestCases = @(
        @{Name = 'singleline';              InputObject = 'singleline';             Expected = "'singleline'"},
        @{Name = "Windows`r`nmultiline";    InputObject = "Windows`r`nmultiline";   Expected = "'Windows`r`nmultiline'"},
        @{Name = "Linux`nmultiline";        InputObject = "Linux`nmultiline";       Expected = "'Linux`nmultiline'"},
        @{Name = '[datetime]$PartyTime';    InputObject = $PartyTime;               Expected = "[datetime]'1999-12-31 23:59:59Z'"},
        @{Name = "[version]'1.2.3.4'";      InputObject = [version]'1.2.3.4';       Expected = "[version]'1.2.3.4'"},
        @{Name = '[DateTimeKind]::Utc';     InputObject = [DateTimeKind]::Utc;      Expected = "'Utc'"},
        @{Name = '{Get-ChildItem foo}';     InputObject = {Get-ChildItem foo};      Expected = '{Get-ChildItem foo}'}
    )

    $ArrayTestCases = (
        @{
            Name        = '@()'
            InputObject = @()
            Expected    = '@()'
        },
        @{
            Name        = '@(1)'
            InputObject = @(1)
            Expected    = '@(1)'
        },
        @{
            Name        = '@($null)'
            InputObject = @($null)
            Expected    = '@($null)'
        },
        @{
            Name        = '@(1, 2, 3)'
            InputObject = @(1, 2, 3)
            Expected    = '@(1, 2, 3)'
        },
        @{
            Name        = '[ArrayList](1, 2, 3)'
            InputObject = [Collections.ArrayList]::new((1, 2, 3))
            Expected    = '@(1, 2, 3)'
        },
        @{
            Name        = "[List[string]]('a', 'b', 'c')"
            InputObject = [Collections.Generic.List[string]]::new([string[]]('a', 'b', 'c'))
            Expected    = "@('a', 'b', 'c')"
        }
    )
}


Describe "ConvertTo-PSExpression" {

    Context "Primitives" {

        It "Serializes <Name> to <Expected>" -ForEach $PrimitiveTestCases {

            $Output = ConvertTo-PSExpression $InputObject

            $Output | Should -BeExactly $Expected
        }

        It "Throws on <Name>" -ForEach $PrimitiveErrorCases {

            {ConvertTo-PSExpression $InputObject} | Should -Throw *$ExpectedError*
        }
    }

    Context "Objects" {

        It "Serializes <Name> to <Expected>" -ForEach $ObjectTestCases {

            $Output = ConvertTo-PSExpression $InputObject

            $Output | Should -BeExactly $Expected
        }
    }

    Context "Collections" {

        It "Serializes <Name> to <Expected>" -ForEach $ArrayTestCases {

            $Output = ConvertTo-PSExpression $InputObject

            $Output | Should -BeExactly $Expected
        }
    }
}
