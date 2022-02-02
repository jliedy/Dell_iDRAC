param ($idracHostname, $fqdn)
# It's required to your iDRAC hostname in DNS in order to utilize SSO
# I set it up to allow one to add the fqdn separately in case you used subdomains like drac1.idrac.example.com
# Command options: .\idrac_sso.ps1 <idrac_hostname> [<fqdn>]

# Should be set to your AD domain
$domain = "example.com"

if ($null -eq $idracHostname) {
    $idracHostname = Read-Host -Prompt "Please enter the iDRAC hostname"
}
if ($null -eq $fqdn) {
    $fqdn = "$idracHostname.$domain"
}

# This configures what keytab will set the account's UPN and SPN to
$principal = "HTTP/$fqdn@"+$domain.ToUpper()
# Destination for keytab file
$keytab = "$idracHostname.keytab"
# Path in AD to create the service account
$userPath = "OU=Dell iDRAC,OU=Service Accounts,DC=example,DC=com"
# AD group to add to the service account.  If one exists, uncomment the below line and change the value.
#$saGroup = "CN=Service Accounts,OU=Security Groups,DC=example,DC=com"
# Set to $true or $false depending on whether or not you prefer to set up NTP for the iDRAC using this script
$setNTP = $true
# If $setNTP is $true, this will be used to set the timezone for the iDRAC
# This may help: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
$timeZone = "EST5EDT"
# Comma separated list of AD Domain Controllers.  Max of 3.
$dcHosts = @("dc1.example.com", "dc2.example.com", "dc3.example.com")

# Creates a randomized password with 20 characters and stores it in cleartext and as a SecureString for use with AD commands and racadm
Add-Type -AssemblyName 'System.Web'
$password = [System.Web.Security.Membership]::GeneratePassword(20, 1)
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

# Tests to see if the AD account exists.  Will create the account if the account doesn't exist, and will modify an existing account and set the password if it does exist.
# Script will create a new password for each run as the keytab needs to be created using the "current" account password.
try {
    $objADUser = Get-ADUser -Identity "$idracHostname" -Server $dcHosts[0]
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        New-ADUser -Name "$idracHostname" -DisplayName "$idracHostname" -Description "Service account to allow Kerberos based SSO on Dell iDRAC" -SamAccountName "$idracHostname" -UserPrincipalName "$idracHostname@$domain" -Path "$userPath" -AccountPassword $securePassword -KerberosEncryptionType AES256 -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true -Server $dcHosts[0]
    } finally {
        Set-ADUser -Identity "$idracHostname" -DisplayName "$idracHostname" -Description "Service account to allow Kerberos based SSO on Dell iDRAC" -SamAccountName "$idracHostname" -UserPrincipalName "$idracHostname@$domain" -KerberosEncryptionType AES256 -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true -Server $dcHosts[0]
        Set-ADAccountPassword -Identity "$idracHostname" -Reset -NewPassword $securePassword -Server $dcHosts[0]
}

# Adds the account to the AD Group if the $saGroup is not commented out
if ($null -ne $saGroup) {
    Add-ADGroupMember -Identity "$saGroup" -Members "$idracHostname" -Server $dcHosts[0]
}

# This is the ktpass command that creates the keytab to be used by the iDRAC
$ktpass = "ktpass -princ '$principal' -mapuser $idracHostname -mapOp set -crypto AES256-SHA1 -ptype KRB5_NT_PRINCIPAL -pass '$password' -out $keytab /target "+$dcHosts[0]
Invoke-Expression $ktpass

# Will ask you the currently-used username and password to access racadmin.
# I got fancy with the AsSecureString bit in an attempt to entering your password into a script a little less bad.
$racUsername = Read-Host -Prompt "Please enter the iDRAC username"
$racSecurePassword = Read-Host -Prompt "Please enter the iDRAC password" -AsSecureString
$racPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($racSecurePassword))
# Depending on your system, you may need to specify the path of the racadm tool
$racCommand = "racadm -r $fqdn -u '$racUsername' -p '$racPassword' --nocertwarn"

# This command uploads the keytab to the iDRAC.  I've had this fail on iDRAC9, so you may need to manually add the keytab
# to the iDRAC via the gui.
$racadmKeytab = "$racCommand krbkeytabupload -f $keytab"
Invoke-Expression $racadmKeytab
$racadmEnableSSO = "$racCommand set iDRAC.ActiveDirectory.SSOEnable 1"
Invoke-Expression $racadmEnableSSO
if ($setNTP) {
    $racadmSetTimezone = "$racCommand set iDRAC.Time.TimeZone $timeZone"
    Invoke-Expression $racadmSetTimezone
    for ($tick = 0; $tick -lt ($dcHosts.length); $tick++) {
        $racadmSetNTP = "$racCommand set iDRAC.NTPConfigGroup.NTP"+($tick + 1)+" "+$dcHosts[$tick]
        Invoke-Expression $racadmSetNTP
    }
    $racadmSetNTPEnable = "$racCommand set iDRAC.NTPConfigGroup.NTPEnable 1"
    Invoke-Expression $racadmSetNTPEnable
}