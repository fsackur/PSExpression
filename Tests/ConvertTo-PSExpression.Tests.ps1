
BeforeDiscovery {

    function New-TestCase ($InputObject, $Expected)
    {
        @{
            InputObject = $InputObject
            Expected    = $Expected
        }
    }

    $TestCases = @(
        ($null, '$null'),
        (0, '0'),
        (1, '1'),
        (-1, '-1')
    ) | ForEach-Object {New-TestCase @_}
}


Describe "ConvertTo-PSExpression" {

    Context "Primitives" {

        It "Serializes <Expected>" -ForEach $TestCases {

            $Output = ConvertTo-PSExpression $InputObject

            $Output | Should -Be $Expected
        }
    }
}
