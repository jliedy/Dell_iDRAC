param ($idracHostname, $fqdn)
# Command options: .\idrac_cert.ps1 <idrac_hostname> [<fqdn>]

# Should be set to your AD domain
$domain = "example.com"

if ($null -eq $idracHostname) {
    $idracHostname = Read-Host -Prompt "Please enter the iDRAC hostname"
}
if ($null -eq $fqdn) {
    $fqdn = "$idracHostname.$domain"
}

$idracIP = [System.Net.Dns]::GetHostAddresses("$fqdn").IPAddressToString

# Set required SSL cert entries for CSR generation.
# SAN will be set as hostname, FQDN and IP of the iDRAC.
$csrOrganizationName = "Org Name"
$csrOrganizationUnit = "Org Unit"
$csrLocalityName = "Locality"
$csrStateName = "State"
$csrCountryCode = "Country Code"
$csrEmailAddr = "group@example.com"
$csrKeySize = "4096"

$crtTemplate = "CA Cert Template"
$crtServer = "CA Hostname"
$crtCA = "CA Name"


# Will ask you the currently-used username and password to access racadmin.
# I got fancy with the AsSecureString bit in an attempt to entering your password into a script a little less bad.
$racUsername = Read-Host -Prompt "Please enter the iDRAC username"
$racSecurePassword = Read-Host -Prompt "Please enter the iDRAC password" -AsSecureString
$racPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($racSecurePassword))
# Depending on your system, you may need to specify the path of the racadm tool
$racCommand = "racadm -r $fqdn -u '$racUsername' -p '$racPassword' --nocertwarn"

$racadmCrt = "$racCommand set iDRAC.Security.CsrCommonName $idracHostname"
Invoke-Expression $racadmCrt
$racadmCrt = "$racCommand set iDRAC.Security.CsrCountryCode $csrCountryCode"
Invoke-Expression $racadmCrt
$racadmCrt = "$racCommand set iDRAC.Security.CsrEmailAddr $csrEmailAddr"
Invoke-Expression $racadmCrt
$racadmCrt = "$racCommand set iDRAC.Security.CsrKeySize $csrKeySize"
Invoke-Expression $racadmCrt
$racadmCrt = "$racCommand set iDRAC.Security.CsrLocalityName $csrLocalityName"
Invoke-Expression $racadmCrt
$racadmCrt = "$racCommand set iDRAC.Security.CsrOrganizationName $csrOrganizationName"
Invoke-Expression $racadmCrt
$racadmCrt = "$racCommand set iDRAC.Security.CsrOrganizationUnit $csrOrganizationUnit"
Invoke-Expression $racadmCrt
$racadmCrt = "$racCommand set iDRAC.Security.CsrStateName $csrStateName"
Invoke-Expression $racadmCrt
$racadmCrt = "$racCommand set iDRAC.Security.CsrSubjectAltName '$idracHostname,$fqdn,$idracIP'"
Invoke-Expression $racadmCrt

$racadmGenCsr = "$racCommand sslcsrgen -g -f $idracHostname.csr"
Invoke-Expression $racadmGenCsr

$signCsr = "certreq -submit -attrib 'CertificateTemplate:$crtTemplate' -config '$crtServer\$crtCA' $idracHostname.csr $idracHostname.crt"
Invoke-Expression $signCsr

$uploadCrt = "$racCommand sslcertupload -t 1 -f $idracHostname.crt"
Invoke-Expression $uploadCrt

$resetRac = "$racCommand racreset soft"
Invoke-Expression $resetRac