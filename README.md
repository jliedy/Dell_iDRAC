# Dell iDRAC Scripts
PowerShell scripts that I've written to deal with the Dell iDRAC.<br>
I'm a bash scripter.  This is my first PowerShell script.  Don't judge me (out loud).

# idrac_ad.ps1
This is for configuring an iDRAC to use Active Directory as the authentication source.  This does not require any special domain permissions.

# idrac_sso.ps1
This is used, in conjunction with the racadm utility, to add a service account to active directory and use that account to generate a keytab.<br>
This script must be run on a Windows server as the ktpass command is not available on desktop releases of Windows.  You must also have domain permissions to add accounts, modify accounts, and reset account passwords.<br>
Passwords are randomly generated each time this script is run and the password is used for the domain account and the keytab.