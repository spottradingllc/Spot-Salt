Function Salt {

<#

.Synopsis

Salt allows commands execution in the same format as accepted by salt command on Linux. 

.Description

Salt executes given salt commands and output jid number that can be used to get job result. It can work together with salt-run command (please see help for salt-run to get some examples).

Salt-Connect must be executed first to get authorized connection to salt master. Otherwise you will get an error.

.Parameter G

Grains glob.

.Parameter Grain_PCRE

Grains PCRE.

.Parameter I

Pillar glob.

.Parameter E

PCRE

.Parameter L

List

.Parameter S

Subnet/IP address

.Parameter N

Node group

.Parameter C

Compound

.Example

salt "*" test.ping

Executes test.ping command on all salt minion.

.Example

Salt –G "application:test" cmd.run "ifconfig" | salt-run -Loud
Executes ifocnfig command on salt minion with the grain application:test and returns job result in the formatted form. 

.Example

Salt -Grain_PCRE 'osrelease:6.*' grains.item osrelease  | Salt-Run -Loud

Gets OS version for all minions that have grain osrelease matching 6.* expression. 

.Example

Salt -C 'P@osrelease:6.*' grains.item osrelease  | Salt-Run –Loud

Gets OS version for all minions that have grain osrelease matching 6.* expression (by using compound matcher)

#>


[CmdletBinding(SupportsShouldProcess = $false, DefaultParameterSetname = "post", ConfirmImpact="Medium")] 

param (

	[Parameter(ParameterSetName = "grains_glob", Mandatory = $true, Position = 0)]
	[switch]
	[Alias("grain")]
    $G,
	
	[Parameter(ParameterSetName = "grains_pcre", Mandatory = $true, Position = 0)]
	[switch]
	$grain_pcre,
	
	[Parameter(ParameterSetName = "pillar", Mandatory = $true, Position = 0)]
	[switch]
	[Alias("pillar")]
    $I,

    [Parameter(ParameterSetName = "pcre", Mandatory = $true, Position = 0)]
	[switch]
	[Alias("pcre")]
    $E,

    [Parameter(ParameterSetName = "list", Mandatory = $true, Position = 0)]
	[switch]
	[Alias("list")]
    $L,

    [Parameter(ParameterSetName = "ipcidr", Mandatory = $true, Position = 0)]
	[switch]
	[Alias("ipcidr")]
    $S,
	
	[Parameter(ParameterSetName = "nodegroup", Mandatory = $true, Position = 0)]
	[switch]
	[Alias("nodegroup")]
    $N,
	
	[Parameter(ParameterSetName = "compound", Mandatory = $true, Position = 0)]
	[switch]
	[Alias("")]
    $C,

    [Parameter(ParameterSetName = "post", Mandatory = $true, Position = 0)]
	[Parameter(ParameterSetName = "grains_glob", Mandatory = $true, Position = 1)]
	[Parameter(ParameterSetName = "grains_pcre", Mandatory = $true, Position = 1)]
	[Parameter(ParameterSetName = "pillar", Mandatory = $true, Position = 1)]
	[Parameter(ParameterSetName = "pcre", Mandatory = $true, Position = 1)]
	[Parameter(ParameterSetName = "list", Mandatory = $true, Position = 1)]
	[Parameter(ParameterSetName = "ipcidr", Mandatory = $true, Position = 1)]
	[Parameter(ParameterSetName = "nodegroup", Mandatory = $true, Position = 1)]
	[Parameter(ParameterSetName = "compound", Mandatory = $true, Position = 1)]
	[string]
    $Target,
	
	[Parameter(ParameterSetName = "post", Mandatory = $true, Position = 1)]
	[Parameter(ParameterSetName = "grains_glob", Mandatory = $true, Position = 2)]
	[Parameter(ParameterSetName = "grains_pcre", Mandatory = $true, Position = 2)]
	[Parameter(ParameterSetName = "pillar", Mandatory = $true, Position = 2)]
	[Parameter(ParameterSetName = "pcre", Mandatory = $true, Position = 2)]
	[Parameter(ParameterSetName = "list", Mandatory = $true, Position = 2)]
	[Parameter(ParameterSetName = "ipcidr", Mandatory = $true, Position = 2)]
	[Parameter(ParameterSetName = "nodegroup", Mandatory = $true, Position = 2)]
	[Parameter(ParameterSetName = "compound", Mandatory = $true, Position = 2)]
	[string]
    $Function,
	
	[Parameter(ParameterSetName = "post", Mandatory = $false, Position = 2)]
	[Parameter(ParameterSetName = "grains_glob", Mandatory = $false, Position = 3)]
	[Parameter(ParameterSetName = "grains_pcre", Mandatory = $false, Position = 3)]
	[Parameter(ParameterSetName = "pillar", Mandatory = $false, Position = 3)]
	[Parameter(ParameterSetName = "pcre", Mandatory = $false, Position = 3)]
    [Parameter(ParameterSetName = "list", Mandatory = $false, Position = 3)]
    [Parameter(ParameterSetName = "ipcidr", Mandatory = $false, Position = 3)]
	[Parameter(ParameterSetName = "nodegroup", Mandatory = $false, Position = 3)]
	[Parameter(ParameterSetName = "compound", Mandatory = $false, Position = 3)]
	[string]
    $Arguments,
	
	[Parameter(ParameterSetName = "post", Mandatory = $false, Position = 3)]
	[Parameter(ParameterSetName = "grains_glob", Mandatory = $false, Position = 4)]
	[Parameter(ParameterSetName = "grains_pcre", Mandatory = $false, Position = 4)]
	[Parameter(ParameterSetName = "pillar", Mandatory = $false, Position = 4)]
	[Parameter(ParameterSetName = "pcre", Mandatory = $false, Position = 4)]
    [Parameter(ParameterSetName = "list", Mandatory = $false, Position = 4)]
    [Parameter(ParameterSetName = "ipcidr", Mandatory = $false, Position = 4)]
	[Parameter(ParameterSetName = "nodegroup", Mandatory = $false, Position = 4)]
	[Parameter(ParameterSetName = "compound", Mandatory = $false, Position = 4)]
	[switch]
    $Loud
  		
)


Begin {
	
	$ErrorActionPreference = "Stop"
		
	Renew-Ticket
	
	If ( $Return.Result -match $False ) { Write-Debug "No result received from $saltMaster" ; break }
	  
    Function Run-SaltState ( $Post ) {
	
		#Error handling
		trap {
	
			If ( $_.Exception.Message -match "Unauthorized" ) {
			
			    Write-Debug "Got Unauthorized response from $saltMaster"

				$Return = New-Object PSObject -Property ([ordered]@{ "Error" = "Unauthorized" ; "Result" = $False })
				
				If ( $Loud ) { return $Return | ft -AutoSize }
				
				Else { return $Return }
			}
						
			continue
		}
					
		$webRequest = [System.Net.WebRequest]::Create( $global:url )
		$webRequest.Method = "POST"
		$webRequest.Headers.Add("X-Auth-Token", $global:Token_Obj.Token)
		$webRequest.Accept = "application/x-yaml"
		$webRequest.ContentType = "application/x-www-form-urlencoded"

		$bytes = [System.Text.Encoding]::ASCII.GetBytes($Post)
		$webRequest.ContentLength = $bytes.Length

		$requestStream = $webRequest.GetRequestStream()
		$requestStream.Write($bytes, 0, $bytes.Length)
		
	
		$requestStream.Close()
		
		$global:reader = New-Object System.IO.Streamreader -ArgumentList $webRequest.GetResponse().GetResponseStream()
	
		Write-Debug "Getting response from salt master..."
		
		$Jobs = $reader.ReadToEnd()

  		$reader.Close()
		
		Write-Debug "Getting JID..."
				
		$Jobs -match "(- jid:) '(.*)'" | Out-Null
		
		$Jid_String = $Matches[2]
		
        $Jid_Object = New-Object PSObject -Property @{ "jid" = $Jid_String }
		
		Write-Debug "Got JID: $Jid_String"
						
		return $Jid_Object
		
	}
	
	$Expr_Form = "glob"
	
	If ( $PSBoundParameters.ContainsKey('G') ) {
		
		Write-Debug "grain"
		$Expr_Form = "grain"
	}
	
	ElseIf ( $PSBoundParameters.ContainsKey('grain_pcre') ) {
		
		Write-Debug "grain_pcre"
		$Expr_Form = "grain_pcre"
	}
	
	ElseIf ( $PSBoundParameters.ContainsKey('I') ) {
		
		Write-Debug "pillar"
		$Expr_Form = "pillar"
	}

    ElseIf ( $PSBoundParameters.ContainsKey('E') ) {
		
		Write-Debug "pcre"
		$Expr_Form = "pcre"
	}

    ElseIf ( $PSBoundParameters.ContainsKey('L') ) {
		
		Write-Debug "list"
		$Expr_Form = "list"
	}

    ElseIf ( $PSBoundParameters.ContainsKey('S') ) {
		
		Write-Debug "ipcidr"
		$Expr_Form = "ipcidr"
	}
	
	ElseIf ( $PSBoundParameters.ContainsKey('N') ) {
		
		Write-Debug "nodegroup"
		$Expr_Form = "nodegroup"
	}
	
	ElseIf ( $PSBoundParameters.ContainsKey('C') ) {
		
		Write-Debug "compund"
		$Expr_Form = "compound"
	}
		
    If ( $Arguments ) {
	
		$SaltArguments = ""
		
		If ( $Function -notmatch "cmd.run" ) {
		
			If ( $Arguments -match "(?:.*)\S(.*)" ) {
		
				$Arg = $Arguments -replace " ", ","

    			$Arg = $Arg -split ","
		
			}
			
			Else {

    			$Arg = $Arguments -replace ", ", ","

    			$Arg = $Arg -split ","
			}
		}
		
		Else {
		
			$Arg = $Arguments -replace ", ", ","

    		$Arg = $Arg -split ","
		
		}
		
    	$Arg | % {
       
        	$SaltArguments = $SaltArguments + "&arg=$_"

    	}

    	If ( $Function -match "state.sls" ) {
			
			If ( $Environment -match "Production" ) {
			
				$SaltArguments = $SaltArguments + "&arg=env=base"
			
			}
			
			Else {
					
				$SaltArguments = $SaltArguments + "&arg=env=$Environment"
			}
    	}
		
		Write-Debug "client=local&tgt=$Target&fun=$Function&timeout=10$SaltArguments&expr_form=$Expr_Form"
		
		$Post = "client=local&tgt=$Target&fun=$Function&timeout=10" + $SaltArguments + "&expr_form=$Expr_Form"
	
	}
	
	Else {
	
		Write-Debug "client=local&tgt=$Target&fun=$Function&timeout=10&expr_form=$Expr_Form"
			
		$Post = "client=local&tgt=$Target&fun=$Function&timeout=10&expr_form=$Expr_Form"
	
	}   
    
       
} #End Begin

Process {
   
   		Run-SaltState $Post	

} # End Process

End {

	$Post = $null
	$SaltArguments = $null
	$Expr_Form = $null
	$Jid_Object = $null
	$Jid_String = $null
	$Jobs = $null
	$Return = $null

}
} # End Salt