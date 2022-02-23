
BeforeDiscovery {

    $PrimitiveTestCases = @(
        '$null',
        '0',
        '1',
        '-1',
        '0.5',
        '-0.5',
        '1/3',
        '[Math]::PI',
        '[uint16]::MinValue',
        '[uint16]::MaxValue',
        '[long]::MinValue',
        '[long]::MaxValue',
        '[int]::MinValue',
        '[int]::MaxValue',
        '[float]::MinValue',
        '[float]::MaxValue',
        '[double]::MinValue',
        '[double]::MaxValue',
        "[char]'c'"
    ) | ForEach-Object {
        $InputObject = Invoke-Expression $_
        @{
            Name        = $_
            InputObject = $InputObject
            Expected    = if ($null -eq $InputObject) {$_} else {$InputObject.ToString()}
        }
    }

    $PrimitiveErrorCases = (
        ('[float]::NaN', "'NaN' of type System.Single"),
        ('[double]::NaN', "'NaN' of type System.Double"),
        ('[float]::NegativeInfinity', "value '-∞' of type System.Single"),
        ('[double]::PositiveInfinity', "value '∞' of type System.Double")
    ) | ForEach-Object {
        $InputObject = Invoke-Expression $_[0]
        @{
            Name        = $_[0]
            InputObject = $InputObject
            Expected    = $_[1]
        }
    }
}


Describe "ConvertTo-PSExpression" {

    Context "Primitives" {

        It "Serializes <Name> to '<Expected>'" -ForEach $PrimitiveTestCases {

            $Output = ConvertTo-PSExpression $InputObject

            $Output | Should -BeExactly $Expected
        }

        It "Throws on <Name>" -ForEach $PrimitiveErrorCases {

            {ConvertTo-PSExpression $InputObject} | Should -Throw *$Expected*
        }
    }
}
