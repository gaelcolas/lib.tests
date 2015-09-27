Function Export-StructuralUnitTestFromCommand {
	param(
		[parameter(Mandatory=$true,ValueFromPipelineByPropertyName = $true,ValueFromPipeline = $true)]
		[System.Management.Automation.CommandInfo[]]
		$command
	)
	begin {
		$strBldr = new-object System.Text.StringBuilder
	}
	process {
		foreach ($cmd in $command)
		{
			$null = $strBldr.Clear()
			$cmdName = $cmd.Name
			$parameters = $cmd.Parameters
			$parameterSets = $cmd.ParameterSets
			$visibility = $cmd.Visibility
			$DefaultParameterSet = $cmd.DefaultParameterSet
			
			#region Testing Output Type
			if($outputType = $cmd.OutputType) {
			foreach ($outType in $OutputType.Type ) #You may have more than one output type
			{
			$outTypeName = $outType.ToString()
				$null = $strBldr.AppendLine(@"
	It 'has an output type of $outTypeName' {
		(Get-Command '$cmdName').OutputType.Type -contains [$outTypeName] | should be `$true
	}
"@)
			 
			}
			}
			#endregion
			
			#region Testing parameter Name/Type
			$uncommonParams = $parameters.keys | Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters -and $_ -notin [System.Management.Automation.PSCmdlet]::OptionalCommonParameters}
			foreach ($parameterKey in $uncommonParams)
			{
				$parameterType = $parameters[$parameterKey].ParameterType
				if($parameterType) { 
					$parameterTypeName = $parameterType.ToString()
					$null = $strBldr.AppendLine(@"
	It 'accept parameter name $($parameters[$parameterKey].Name) as type $($parameters[$parameterKey].ParameterType.ToString())' {
		(Get-Command '$cmdName').Parameters['$parameterKey'].ParameterType.ToString() | should be $parameterTypeName
	}
"@)
				}
			}
			#endregion
			
			
			if($strBldr.ToString() -ne [string]::Empty) {
				$null = $strBldr.insert(0,"Describe '$cmdName' {`r`n ")
				$null = $strBldr.AppendLine('}')
				Write-Output $strBldr.ToString()
			}
		}
	}
	
}