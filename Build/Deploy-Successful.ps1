param (
  [string]$ServerName = "cpm-dev-app01.devid.local",
  [string]$SiteName
)

$url = ("https://{0}/{1}" -f $ServerName, $SiteName)
Write-Host ("Testing URL {0}" -f $url)

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


$page = Invoke-WebRequest -Uri $url -UseBasicParsing
if ($? -eq $False)
{
  Write-Host "  ERROR:  Invoke-WebRequest failed"
  exit 1
}

if ($page.Content.Contains("Crimson Common Authentication") -eq $False)
{
  Write-Host "  ERROR:  Page returned, but not CMGA login page."
  exit 1
}

Write-Host "  Success:  Login page found."
exit 0
