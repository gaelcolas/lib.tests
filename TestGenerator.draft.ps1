Function Export-StructuralUnitTestFromCommand {
    param(
        [parameter(Mandatory=$true,ValueFromPipelineByPropertyName = $true,ValueFromPipeline = $true)]
        [System.Management.Automation.CommandInfo[]]
        $command
    )
    begin {
        $stringBuilder = New-object -TypeName System.Text.StringBuilder
        $BuiltInParameters = ([Management.Automation.PSCmdlet]::CommonParameters + [Management.Automation.PSCmdlet]::OptionalCommonParameters)
    }
    process {
        
        foreach ($cmd in $command)
        {
        $null = $stringBuilder.Clear()
        $cmdName = $cmd.Name
        $cmdDefaultParameterSet = $cmd.DefaultParameterSet

        $null = $stringBuilder.AppendLine(@"
Describe '$cmdName' {
    #getting Command Metadata
    `$command = (Get-Command '$cmdName')

    It 'has $cmdDefaultParameterSet as Default parameterSet' {
        `$command.defaultParameterSet | Should be '$cmdDefaultParameterSet'
    }
"@)

        $outputTypes = $cmd.OutputType
        foreach ($outputType in $outputTypes)
        {
            $outputTypeName = $outputType.Name
            #It 'Output the Type $outputType'
            $null = $stringBuilder.AppendLine(@"
    It 'contains an outputType of Type $outputTypeName' {
        `$command.OutputType.Type -contains [$outputTypeName] | should be `$true
    }

"@)
        }

        $parameterSets = $cmd.ParameterSets
        foreach ($ParameterSet in $parameterSets)
        {
            $ParameterSetName = $ParameterSet.Name
            $null = $stringBuilder.AppendLine(@"
    Context 'ParameterSetName $ParameterSetName' {

        It 'has a parameter Set of Name $ParameterSetName' {
            `$command.ParameterSets.Name -contains '$ParameterSetName' | Should be $true
        }
        `$ParameterSet = `$command.ParameterSets | Where-Object { `$_.'Name' -eq '$ParameterSetName' }
"@)
            $parameters = $ParameterSet.Parameters | Where-Object { $_.Name -notin $BuiltInParameters}
            foreach ($parameter in $parameters)
            {
                $ParameterName = $parameter.Name
                $TypeName = $parameter.ParameterType.ToString()
                $isMandatory = $parameter.isMandatory
                $ValueFromPipeline = $parameter.ValueFromPipeline
                $ValueFromPipelineByPropertyName = $parameter.ValueFromPipelineByPropertyName
                $ValueFromRemainingArguments = $parameter.ValueFromRemainingArguments
                $Position = $parameter.Position

                $null = $stringBuilder.AppendLine(@"
        
        `$Parameter = `$ParameterSet.Parameters | Where-Object { `$_.'Name' -eq '$ParameterName' }

        It 'has compatible parameter $ParameterName' {
            `$Parameter | Should Not BeNullOrEmpty
            `$Parameter.ParameterType.ToString() | Should be $TypeName
            `$Parameter.IsMandatory | Should be `$$([bool]$isMandatory)
            `$Parameter.ValueFromPipeline | Should be `$$([bool]$ValueFromPipeline)
            `$Parameter.ValueFromPipelineByPropertyName | Should be `$$([bool]$ValueFromPipelineByPropertyName)
            `$Parameter.ValueFromRemainingArguments | Should be `$$([bool]$ValueFromRemainingArguments)
            `$Parameter.Position | Should be $Position
        }
"@)
                }

            #Closing Context block
            $null = $stringBuilder.AppendLine('    }')
            }

   #Closing Describe Statement
        $null = $stringBuilder.AppendLine('}')
        Write-Output $stringBuilder.ToString()
        }
    }   
    
}