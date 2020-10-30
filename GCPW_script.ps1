<# 
This script downloads Google Credential Provider for Windows from
https://tools.google.com/dlpage/gcpw/, then installs and configures it.
Windows administrator access is required to use the script. 
Prepare to install GCPW info >> https://support.google.com/a/answer/9543613

++ it will also install chrome for you
#>

<# 
TODO
1. Save/Download this script
2. Edit the script to include your domain's in line XX
3. Open powershell as admin by Shift and right click at windows "Start"
4. Run  and approve (y) the following command so that machine allows scripts : 
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
5. Run the script. 
Shift and right click on script >> copy as path >> paste that into powershell windows and remove quotation marks >> Enter
6. Run  and approve (y) the following command so that machine blocks scripts : 
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy restricted

DONE

you may need to later make that person an admin or you can configure that here: 
https://admin.google.com/ac/appsettings/724141353720/WindowsAdministrativeSettingsTab?vid=EMM_WINDOWS_MANAGEMENT_VIEW
#>

$domainsAllowedToLogin = ""       # <<< PUT IT HERE, eg "acme1.com,acme2.com"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

<# Check if one or more domains are set #>
if ($domainsAllowedToLogin.Equals('')) {
    $msgResult = [System.Windows.MessageBox]::Show('The list of domains cannot be empty! Please edit this script.', 'GCPW', 'OK', 'Error')
    exit 5
}

function Is-Admin() {
    $admin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match 'S-1-5-32-544')
    return $admin
}

<# Check if the current user is an admin and exit if they aren't. #>
if (-not (Is-Admin)) {
    $result = [System.Windows.MessageBox]::Show('Please run as administrator!', 'GCPW', 'OK', 'Error')
    exit 5
}

<# Choose the Chrome file to download. 32-bit and 64-bit versions have different names #>
$chromeFileName = 'googlechromestandaloneenterprise.msi'
if ([Environment]::Is64BitOperatingSystem) {
    $chromeFileName = 'googlechromestandaloneenterprise64.msi'
}

<# Choose the GCPW file to download. 32-bit and 64-bit versions have different names #>
$gcpwFileName = 'gcpwstandaloneenterprise.msi'
if ([Environment]::Is64BitOperatingSystem) {
    $gcpwFileName = 'gcpwstandaloneenterprise64.msi'
}

<# Download the GCPW installer. #>
$gcpwUrlPrefix = 'https://dl.google.com/credentialprovider/'
$gcpwUri = $gcpwUrlPrefix + $gcpwFileName
Write-Host 'Downloading GCPW from' $gcpwUri
Invoke-WebRequest -Uri $gcpwUri -OutFile $gcpwFileName

<# Run the Chrome installer and wait for the installation to finish #>
$arguments = "/i `"$chromeFileName`""
$installProcess = (Start-Process msiexec.exe -ArgumentList $arguments -PassThru -Wait)

<# Run the Chrome installer and wait for the installation to finish #>
$arguments = "/i `"$chromeFileName`""
$installProcess = (Start-Process msiexec.exe -ArgumentList $arguments -PassThru -Wait)

<# Check if installation was successful #>
if ($installProcess.ExitCode -ne 0) {
    $result = [System.Windows.MessageBox]::Show('Installation failed!', 'Chrome', 'OK', 'Error')
    exit $installProcess.ExitCode
}
else {
    $result = [System.Windows.MessageBox]::Show('Installation completed successfully!', 'Chrome', 'OK', 'Info')
}

<# Run the GCPW installer and wait for the installation to finish #>
$arguments = "/i `"$gcpwFileName`""
$installProcess = (Start-Process msiexec.exe -ArgumentList $arguments -PassThru -Wait)

<# Check if installation was successful #>
if ($installProcess.ExitCode -ne 0) {
    $result = [System.Windows.MessageBox]::Show('Installation failed!', 'GCPW', 'OK', 'Error')
    exit $installProcess.ExitCode
}
else {
    $result = [System.Windows.MessageBox]::Show('Installation completed successfully!', 'GCPW', 'OK', 'Info')
}

<# Set the required registry key with the allowed domains #>
$registryPath = 'HKEY_LOCAL_MACHINE\Software\Google\GCPW'
$name = 'domains_allowed_to_login'
[microsoft.win32.registry]::SetValue($registryPath, $name, $domainsAllowedToLogin)

$domains = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($domains -eq $domainsAllowedToLogin) {
    $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
}
else {
    $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')

}
