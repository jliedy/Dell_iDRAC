param ($idracHostname, $fqdn)
# It's really a good idea to have your iDRAC hostname in DNS, especially if you plan on setting up SSO.
# I set it up to allow one to add the fqdn separately in case you used subdomains like drac1.idrac.example.com

# Should be set to your AD domain
$domain = "example.com"

if ($idracHostname -eq $null) {
    $idracHostname = Read-Host -Prompt "Please enter the iDRAC hostname"
}
if ($fqdn -eq $null) {
    $fqdn = "$idracHostname.$domain"
}

# Comma separated list AD groups
$adGroups = @("AD Group samAccountName1", "AD Group samAccountName2")
# Comma separated list of each of the above listed AD group's iDRAC permission level in HEX.  "0x1ff" is for Administrator access.
$adGroupsPrivs = @("0x1ff", "0x0")
# Comma separated list of AD Domain Controllers.  Max of 3.
$dcHosts = @("dc1.example.com", "dc2.example.com", "dc3.example.com")

# Checks to make sure there are an equal amount of entries in the below arrays.
if ($adGroups.length -ne $adGroupsPrivs.length) {
    Throw "Number of adGroups and adGroupsPrivs differs.  Please correct."
}

# Will ask you the currently-used username and password to access racadmin.
# I got fancy with the AsSecureString bit in an attempt to entering your password into a script a little less bad.
$racUsername = Read-Host -Prompt "Please enter the iDRAC username"
$racSecurePassword = Read-Host -Prompt "Please enter the iDRAC password" -AsSecureString
$racPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($racSecurePassword))
# Depending on your system, you may need to specify the path of the racadm tool
$racCommand = "racadm -r $fqdn -u '$racUsername' -p '$racPassword' --nocertwarn"


$racadmADEnable = "$racCommand set iDRAC.ActiveDirectory.Enable 1"
Invoke-Expression $racadmADEnable
$racadmADSchema = "$racCommand set iDRAC.ActiveDirectory.Schema 2"
Invoke-Expression $racadmADSchema
$racadmADLookup = "$racCommand set iDRAC.ActiveDirectory.DCLookupDomainName $domain"
Invoke-Expression $racadmADLookup
$racadmADGCRoot = "$racCommand set iDRAC.ActiveDirectory.GCRootDomain $domain"
Invoke-Expression $racadmADGCRoot
$racadmADUserDomain = "$racCommand set iDRAC.UserDomain.1.Name $domain"
Invoke-Expression $racadmADUserDomain
for ($tick = 0; $tick -lt ($adGroups.length); $tick++) {
    $racadmADGroupName = "$racCommand set iDRAC.ADGroup."+($tick + 1)+".Name '"+$adGroups[$tick]+"'"
    Invoke-Expression $racadmADGroupName
    $racadmADGroupDomain = "$racCommand set iDRAC.ADGroup."+($tick + 1)+".Domain '$domain'"
    Invoke-Expression $racadmADGroupDomain
    $racadmADGroupPrivilege = "$racCommand set iDRAC.ADGroup."+($tick + 1)+".Privilege '"+$adGroupsPrivs[$tick]+"'"
    Invoke-Expression $racadmADGroupPrivilege
}
for ($tick = 0; $tick -lt ($dcHosts.length); $tick++) {
    $racadmADDC = "$racCommand set iDRAC.ActiveDirectory.DomainController"+($tick + 1)+" "+$dcHosts[$tick]
    Invoke-Expression $racadmADDC
    $racadmADGC = "$racCommand set iDRAC.ActiveDirectory.GlobalCatalog"+($tick + 1)+" "+$dcHosts[$tick]
    Invoke-Expression $racadmADGC
}