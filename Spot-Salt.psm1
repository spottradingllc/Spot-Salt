$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Internal Functions
. $here\Functions\Renew-Ticket.ps1

# User facing functions
. $here\Functions\Salt-Connect.ps1
. $here\Functions\Salt-Run.ps1
. $here\Functions\Salt.ps1

