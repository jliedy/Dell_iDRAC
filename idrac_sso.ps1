param ($idracHostname, $fqdn)

$domain = "example.com"

if ($idracHostname -eq $null) {
    $idracHostname = Read-Host -Prompt "Please enter the iDRAC hostname"
}
if ($fqdn -eq $null) {
    $fqdn = "$idracHostname.$domain"
}

$dcHostname = "dc1.$domain"
$principal = "HTTP/$fqdn@$domain.ToUpper()"
$keytab = "$idracHostname.keytab"
$userPath = "OU=Dell iDRAC,OU=Service Accounts,DC=example,DC=com"
$saGroup = "CN=Service Accounts,OU=Security Groups,DC=example,DC=com"
$timeZone = "EST5EDT"

$dchost1 = "dc1.example.com"
$dchost2 = "dc2.example.com"
$dchost3 = "dc3.example.com"

Add-Type -AssemblyName 'System.Web'
$password = [System.Web.Security.Membership]::GeneratePassword(20, 1)
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

$objADUser = $null

try {
    $objADUser = Get-ADUser -Identity "$idracHostname" -Server $dcHostname
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    New-ADUser -Name "$idracHostname" -DisplayName "$idracHostname" -Description "Service account to allow Kerberos based SSO on Dell iDRAC" -SamAccountName "$idracHostname" -UserPrincipalName "$idracHostname@$domain" -Path "$userPath" -AccountPassword $securePassword -KerberosEncryptionType AES256 -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true -Server $dcHostname
}
finally {
    Set-ADUser -Identity "$idracHostname" -DisplayName "$idracHostname" -Description "Service account to allow Kerberos based SSO on Dell iDRAC" -SamAccountName "$idracHostname" -UserPrincipalName "$idracHostname@$domain" -KerberosEncryptionType AES256 -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true -Server $dcHostname
    Set-ADAccountPassword -Identity "$idracHostname" -Reset -NewPassword $securePassword -Server $dcHostname
}

Add-ADGroupMember -Identity "$saGroup" -Members "$idracHostname" -Server $dcHostname
$ktpass = "ktpass -princ $principal -mapuser $idracHostname -mapOp set -crypto AES256-SHA1 -ptype KRB5_NT_PRINCIPAL -pass '$password' -out $keytab /target $dcHostname"
Invoke-Expression $ktpass

$racUsername = Read-Host -Prompt "Please enter the iDRAC username"
$racSecurePassword = Read-Host -Prompt "Please enter the iDRAC password" -AsSecureString
$racPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($racSecurePassword))
$racCommand = "racadm -r $fqdn -u $racUsername -p '$racPassword' --nocertwarn"

$racadmKeytab = "$racCommand krbkeytabupload -f $keytab"
Invoke-Expression $racadmKeytab
$racadmEnableSSO = "$racCommand set iDRAC.ActiveDirectory.SSOEnable 1"
Invoke-Expression $racadmEnableSSO
$racadmSetTimezone = "$racCommand set iDRAC.Time.TimeZone $timeZone"
Invoke-Expression $racadmSetTimezone
$racadmSetNTP1 = "$racCommand set iDRAC.NTPConfigGroup.NTP1 $dcHost1"
Invoke-Expression $racadmSetNTP1
$racadmSetNTP2 = "$racCommand set iDRAC.NTPConfigGroup.NTP2 $dcHost2"
Invoke-Expression $racadmSetNTP2
$racadmSetNTP3 = "$racCommand set iDRAC.NTPConfigGroup.NTP3 $dcHost3"
Invoke-Expression $racadmSetNTP3
$racadmSetNTPEnable = "$racCommand set iDRAC.NTPConfigGroup.NTPEnable 1"
Invoke-Expression $racadmSetNTPEnable