Function Salt-Connect {

<#

.Synopsis

Salt-Connect creates connection to Salt master in the specified environment.

.Description

Salt-Connect creates authenticated connection to Salt API in the given environment so we can start executing commands against Salt minions or master.
It will change your PowerShell prompt to denote salt master you are connected to.

.Parameter saltMaster

Name of the Salt master you are trying to connect to.

.Parameter Loud

Formats error output for easy reading. Use it of you are working interactively, skip if you need to capture error output in your script.

.Example

Salt-Connect saltStaging

Connects to saltStaging master. This is equivalent of the command Salt-Connect -M saltStaging or Salt-Connect -saltMaster saltStaging

.Example

Salt-Connect saltStaging -Loud

Connects to saltStaging master and displays formatted error output in case master is not responding.

.Example

$master = saltStaging ; $master | Salt-Connect

Connects to saltStaging master by using value from pipeline.

#>

[CmdletBinding(SupportsShouldProcess = $false, DefaultParameterSetname = "connect", ConfirmImpact="Medium")] 

param (

	[Parameter(ParameterSetName = "connect", Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $True,
				ValueFromPipeline = $True)]
	[ValidatePattern("saltStaging|saltUAT|saltProduction")]
    [Alias("M")]
	[string]
    $saltMaster, 
	
	[Parameter(ParameterSetName = "connect", Mandatory = $false, Position = 1)]
	[switch]
    $Loud

)

	$ErrorActionPreference = "Stop"
	
	#Error handling
	trap {
	
		Write-Debug $_.Exception.Message

		If ( $_.Exception.Message -match "500|connect to the remote server" ) {

			$Return = New-Object PSObject -Property ([ordered]@{ "Error" = "Salt API Down" ; "Result" = $False })
			
			If ( $Loud ) {
				
				return $Return | ft -AutoSize
			}
			
			Else {
			
				return $Return
			}
		}
		
		continue
	}

	Switch -regex ( $saltMaster ) {

        "saltStaging" { 
		
			$Environment = "Staging" 
			$global:Color = "Magenta"	
		}

        "saltUAT" { 
		
			$Environment = "UAT" 
			$global:Color = "Cyan"		
		}

        "saltProduction" { 
		
			$Environment = "Production" 	
			$global:Color = "Red"
		}
        
    }
			
	$global:saltMaster_Url = "http://" + $saltMaster + ":8000"
		
	$urlLogin = $saltMaster_Url + "/login"
    $global:url = $saltMaster_Url + "/minions"
	
    # Getting token for authentication
    $json = "{`"username`": `"salt`", `"password`": `"salt`", `"eauth`": `"pam`"}"
    
	$ExperationTime = (Get-Date).Addhours(9)
	
	Write-Debug "Getting authentication token..."
	
	$Token = (Invoke-RestMethod -Uri $urlLogin -Method Post -Body $json -ContentType "application/json").return.token
	
	$global:Token_Obj = New-Object PSObject -Property @{ "Token" = $Token ; "Experation" = [datetime]$ExperationTime }
	
	Write-Debug "Token: $Token_Obj"
	
	$global:saltMaster_Prompt = $saltMaster
			
	Function global:Prompt {
			
		Write-Host "PS [$global:saltMaster_Prompt] $PWD>" -NoNewline -ForegroundColor $Color
		
		return " "
		
	}
	
	$Token = $null

}