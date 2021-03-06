Function Renew-Ticket {

	$ErrorActionPreference = "Stop"

	#Error handling
	trap {
	
		If ( $_.Exception.Message -match "Cannot index into a null array" ) {
			
			$Return = New-Object PSObject -Property ([ordered]@{ "Error" = "Not Connected to Salt Master" ; "Result" = $False })

			return $Return
			
		}
	
		continue
	}

	$CurrentTime = Get-Date

	If ( $CurrentTime -le $global:Token_Obj.Experation ) {

		Write-Debug "Token did not expire. Nothing to do."

	}

	Else {

		Write-Debug "Renewing token..."
		
		$RegEx = "http://(.*):8000"

		$global:saltMaster_Url -match $RegEx | Out-Null

		$saltMaster = $Matches[1]
		
		Write-Debug "Connecting to $saltMaster"

		Salt-Connect $saltMaster
	}
}