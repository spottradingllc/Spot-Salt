### Spot-Salt Module

We use this module to get server grains from salt API so we can use it in [UnusedServers PowerShell module](https://github.com/spottradingllc/unused-servers).

### Installation

1. Determine PowerShell modules directory you want to use (type `$env:PSModulePath` and chose one, for example `c:\Windows\system32\WindowsPowerShell\v1.0\Modules`).
2. Download repo and place all files under Modules directory you chose in the first step into `Spot-Salt` folder (`c:\Windows\system32\WindowsPowerShell\v1.0\Modules\Spot-Salt`).
3. Make sure the files are not blocked. Right click on the files and un-block them by going into properties.
4. Make sure to set your PowerShell Execution Policy to `RemoteSigned`, for example `Set-ExecutionPolicy RemoteSigned -Force`.
5. Type `Get-Module -ListAvailable` and make sure you see Spot-Salt module in the list

### Usage

`help Salt-Connect -Detailed`

`help Salt -Detailed`

`help salt-Run -Detailed`

### Examples

`salt-Connect saltStaging`: connects to saltStaging salt master and obtains security token

`salt "TEST*" cmd.run "ifconfig"`: runs ifconfig on TEST server. This will return JID number that you can use with salt-Run command

`salt-Run 20151001150618354722`: will return result for job ID 20151001150618354722 as an object.

`salt "TEST*" cmd.run "ifconfig" | salt-run -Loud`: will return results of the command to the console in a nice format

`salt -E "TEST0(1|2|3)" grains.items | salt-run`: will return all grains for three servers TEST01, TEST02, TEST03 as an object so it is easy to consume it in another scipt
