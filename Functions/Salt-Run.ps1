Function Salt-Run {

<#

.Synopsis

Salt-Run gets job results based on the jid number (equivalent to salt-run jobs.lookup_jid)

.Description

Salt-Run connects to Salt API and gets job results based on the jid number. It will try to get result 5 times in a row with 2 seconds delay between the tries.

Salt-Run automatically reconnects to salt master if the authorization token expired.

.Parameter Jid

Jid number of the salt job.

.Parameter Loud

Formats error output for easy reading. Use it of you are working interactively, skip if you need to capture error output in your script.

.Example

Salt-Run 20140714150702830488

Gets job result for jid 20140714150702830488. You can also use Salt-Run –jid 20140714150702830488.

.Example

Salt-Run 20140714150702830488 -Loud

Gets job result for jid 20140714150702830488 and formats results for easy reading in PowerShell window.

.Example

Salt "*" test.ping | salt-run -Loud

Executes test.ping command on all salt minions and returns formatted result.

#>

[CmdletBinding(SupportsShouldProcess = $false, DefaultParameterSetname = "result", ConfirmImpact="Medium")] 

param (

    [Parameter(ParameterSetName = "result", Mandatory = $true, ValueFromPipelineByPropertyName = $True, 
	 			ValueFromPipeline = $True, Position = 0)]
	[string]
    $Jid,
	
	[Parameter(ParameterSetName = "result", Mandatory = $false, Position = 1)]
	[switch]
    $Loud
)

Begin {

	$ErrorActionPreference = "Stop"
	
	Renew-Ticket
	
}

Process {

	#Error handling
	trap {

		If ( $_.Exception.Message -match ".500. Internal Server Error" ) {
			
			$Return = New-Object PSObject -Property ([ordered]@{ "jid" = $Jid ; "Error" = "Got 500 Error from salt API" ; "Result" = $False })
					
			If ( $Loud ) { return $Return | ft -AutoSize }
					
			Else { return $Return }
		}
		
		Else { 
			
			If ( ! $DebugPreference -match "Continue" ) { cls }
						
			If ( $Loud ) { Write-Host "Getting resuls..." -ForegroundColor Green }
			
			Start-Sleep 3
			
			Salt-Run $Jid
		}
								
		continue
	}

    If ( $Jid -match $False ) { 
	
			$Return = New-Object PSObject -Property ([ordered]@{ "jid" = "No jid" ; "Result" = $False })
			
			If ( $Loud ) { return $Return | ft -Wrap -AutoSize }
			
			Else { return $Return }
	}
	
	ElseIf ( $Jid -notmatch "\A[\d.+]{20}\Z" ) { 
	
		$Return = New-Object PSObject -Property ([ordered]@{ "jid" = "Incorrect syntax or empty string" ; "Result" = $False })
		
		If ( $Loud ) { return $Return | ft -AutoSize }
		
		Else { return $Return }
	}
	
    Else {
       
	   	$Count = 0
		
        Function Internal {
		
			$Count ++

	        $urlJobs = $global:saltMaster_Url + "/jobs/" + $Jid
		
		    $Header = @{ "X-Auth-Token" = $global:Token_Obj.Token }
			
			Write-Debug "Getting salt results..."
	
			$Results = Invoke-RestMethod -Uri $urlJobs -Method Get -ContentType "application/x-yaml" -Headers $Header -TimeoutSec 30
			
			$ResultsJSON = $Results
		
		    If ( ($ResultsJSON.return | Out-String).Length -ne 2 -and $ResultsJSON.return -notmatch "Welcome"  ) {
			
				If ( ! $DebugPreference -match "Continue" ) { cls }
				
				$minion = ($ResultsJSON.return | gm | ? { $_.Name -match ".com" } | Select Name).Name
			    	
			    If ( $minion.Count -eq 1 ) {
				
				    $minion -match "(.*)`.spottrading.com" | Out-Null

				    $minion = $Matches[1]
				
				    $ResultsFinal = $ResultsJSON.return | Select -ExpandProperty *
					
					If ( $Loud ) { 
					
						If ( ($ResultsFinal | gm -MemberType NoteProperty).Count -eq 0 ) {  
						
							$ResultsFinal_Obj = New-Object PSObject -Property ( [ordered]@{ "Minion" = $minion ; "Result" = $ResultsFinal } )
							
							return $ResultsFinal_Obj | ft -AutoSize -Wrap
						}
						
						Else {
																				
							$ResultsFinal_Obj = New-Object PSObject -Property ( [ordered]@{ "Minion" = $minion ; "Result" = $ResultsFinal } )
							
							return $ResultsFinal_Obj | ConvertTo-Json
						}
					}
					
					Else { 
					
						$ResultsFinal_Obj = New-Object PSObject -Property ( [ordered]@{ "Minion" = $minion ; "Result" = $ResultsFinal } )
						
						Write-Debug $ResultsFinal_Obj
						
						return $ResultsFinal_Obj
					}
			    }
			
			    Else { 
				
					If ( $Loud ) { $ResultsJSON.return | ConvertTo-Json }
					
					Else { return $ResultsJSON }
				}
		    }
			
		    Else {
				
				#Trying to get result 5 times. Return jid after that (for manual verification - salt-run $jid).
				If ( $Count -le 5 ) {
					
					If ( $Loud ) { 
					
						Write-Host "$Count attempt to get results (max 5)..." -ForegroundColor Yellow 
                        Start-Sleep 2
						Internal
					}
					
					Else { Start-Sleep 2 ;  Internal }
				}

	            Else { 
				
					$Return = New-Object PSObject -Property ([ordered]@{ "jid" = $Jid ; "Error" = "No results received" ; "Result" = $False })
					
					If ( $Loud ) { return $Return | ft -AutoSize }
					
					Else { return $Return }
				}
		    }
			
		} #End Internal
		
	Internal
    
	}
}

End { 
    
    $ResultsJSON = $null
    $ResultsFinal = $null    
	$ResultsFinal_Obj = $null
	$Results = $null
	$Return = $null
	$Count = $null
	$Array = $null
}

}