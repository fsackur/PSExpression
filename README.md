# PSExpression

[![Build status](https://ci.appveyor.com/api/projects/status/pjja5bqxkxd47hxg/branch/main?svg=true)](https://ci.appveyor.com/project/fsackur/psexpression/branch/main)

Flatten objects into runnable PowerShell syntax.

Like `ConvertTo-Json`, but without the extra step to get the objects back.

``` powershell
> ConvertTo-PSExpression @{foo = 'bar'}

@{foo = 'bar'}
```

``` powershell
> $Sport = New-Object PSObject -Property @{ping = 'pong'}
> ConvertTo-PSExpression $Sport

[pscustomobject]@{ping = 'pong'}
```
