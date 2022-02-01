param ($idracHostname)

if ($idracHostname -eq $null) {
    $idracHostname = Read-Host -Prompt "Please enter the iDRAC hostname"
}

$domain = "example.com"
$fqdn = "$idracHostname.$domain"

$adgroup1 = "AD Group SamAccountName"

$dchost1 = "hostname1.example.com"
$dchost2 = "hostname2.example.com"
$dchost3 = "hostname3.example.com"

$racUsername = Read-Host -Prompt "Please enter the iDRAC username"
$racSecurePassword = Read-Host -Prompt "Please enter the iDRAC password" -AsSecureString
$racPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($racSecurePassword))
$racCommand = "racadm -r $fqdn -u $racUsername -p '$racPassword' --nocertwarn"

$racadmADEnable = "$racCommand set iDRAC.ActiveDirectory.Enable 1"
Invoke-Expression $racadmADEnable
$racadmADSchema = "$racCommand set iDRAC.ActiveDirectory.Schema 2"
Invoke-Expression $racadmADSchema
$racadmADLookup = "$racCommand set iDRAC.ActiveDirectory.DCLookupDomainName $domain"
Invoke-Expression $racadmADLookup
$racadmADGCRoot = "$racCommand set iDRAC.ActiveDirectory.GCRootDomain $domain"
Invoke-Expression $racadmADGCRoot
$racadmADUserDomain1 = "$racCommand set iDRAC.UserDomain.1.Name $domain"
Invoke-Expression $racadmADUserDomain1
$racadmADGroup1Name = "$racCommand set iDRAC.ADGroup.1.Name '$adgroup1'"
Invoke-Expression $racadmADGroup1Name
$racadmADGroup1Domain = "$racCommand set iDRAC.ADGroup.1.Domain '$domain'"
Invoke-Expression $racadmADGroup1Domain
$racadmADGroup1Privelege = "$racCommand set iDRAC.ADGroup.1.Privilege '0x1ff'"
Invoke-Expression $racadmADGroup1Privelege
$racadmADDC1 = "$racCommand set iDRAC.ActiveDirectory.DomainController1 $dchost1"
Invoke-Expression $racadmADDC1
$racadmADDC2 = "$racCommand set iDRAC.ActiveDirectory.DomainController2 $dchost2"
Invoke-Expression $racadmADDC2
$racadmADDC3 = "$racCommand set iDRAC.ActiveDirectory.DomainController3 $dchost3"
Invoke-Expression $racadmADDC3
$racadmADGC1 = "$racCommand set iDRAC.ActiveDirectory.GlobalCatalog1 $dchost1"
Invoke-Expression $racadmADGC1
$racadmADGC2 = "$racCommand set iDRAC.ActiveDirectory.GlobalCatalog2 $dchost2"
Invoke-Expression $racadmADGC2
$racadmADGC3 = "$racCommand set iDRAC.ActiveDirectory.GlobalCatalog3 $dchost3"
Invoke-Expression $racadmADGC3