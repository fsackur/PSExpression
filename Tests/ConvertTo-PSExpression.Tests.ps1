
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
}


Describe "ConvertTo-PSExpression" {

    Context "Primitives" {

        It "Serializes <Name> to '<Expected>'" -ForEach $PrimitiveTestCases {

            $Output = ConvertTo-PSExpression $InputObject

            $Output | Should -BeExactly $Expected
        }
    }
}
