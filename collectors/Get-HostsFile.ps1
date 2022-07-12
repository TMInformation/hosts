#Requires -Version 6.0
[CmdletBinding()]
param (
 [string]$Path
)

try {
 $ErrorActionPreference = 'Stop';
 $Error.Clear();

 #
 # Where is the script running from
 #
 Write-Verbose "Checking script path";
 $ScriptPath = $PSScriptRoot;

 #
 # Set Platform variable to null
 #
 Write-Verbose "Setting Platform variable to empty string";
 $Platform = '';

 #
 # Read in datasource JSON
 #
 Write-Verbose "Read dataSorurce JSON";
 $dataSource = Get-Content "$($ScriptPath.Replace('collectors','dataSource'))\hosts.json" | ConvertFrom-Json

 #
 # Check for authentication
 #
 Write-Verbose "Check for authentication information";
 if ($dataSource.connectionInfo.ToString() -eq '') {
  Write-Host "ConnectionInformation not defined" -ForegroundColor Yellow;
 }

 #
 # Check platform
 #
 Write-Verbose "Check what platform we are running in";
 if ($dataSource.platform.Windows) {
  Write-Host "Windows is supported" -ForegroundColor Green;
  if ($PSVersionTable.OS -like "*Windows*") {
   Write-Host "Collector running on Windows" -ForegroundColor Green;
   $Platform = 'windows';
  }
 }

 if ($dataSource.platform.Linux) {
  Write-Host "Linux is supported" -ForegroundColor Green;
  if ($PSVersionTable.OS -like "*Linux*") {
   Write-Host "Collector running on Linux" -ForegroundColor Green;
   $Platform = 'linux';
  }
 }

 #
 # Set default path if empty
 #
 Write-Verbose "Check if Path is empty";
 if ([string]::IsNullOrEmpty($Path)) {
  Write-Host "Setting default hosts path" -ForegroundColor Yellow;
  switch ($Platform) {
   'windows' {
    $Path = 'C:\Windows\System32\drivers\etc\hosts';
   }
   'linux' {
    $Path = '/etc/hosts';
   }
  }
 }

 #
 # Collect the data
 #
 Write-Verbose "Read in hosts file";
 Write-Host "Collecting data from $($dataSource.dataSource.name)" -ForegroundColor Green;
 $hostsFile = Get-Content -Path $Path;

 #
 # Clean up input, remove comments and blank lines
 #
 Write-Verbose "Clean up hosts file";
 $hostsFile = $hostsFile | foreach { if (!($_.StartsWith('#'))) { $_ } };
 $hostsFile = $hostsFile | foreach { if (!($_.trim().Startswith('#'))) { $_ } };
 $hostsFile = $hostsFile | foreach { if (!($_ -eq '' )) { $_ } };

 #
 # Normalize input, single space between ipAddress and host
 #
 Write-Verbose "Normalize the spacing";
 $hostsFile = $hostsFile | foreach { $_ -replace '\s+', ' ' };

 #
 # Output the discovered data
 #
 Write-Verbose "Output processed data";
 return ($hostsFile | foreach { New-Object -TypeName psobject -Property @{ipAddress = $_.Split(' ')[0]; host = $_.Split(' ')[1] } }) |ConvertTo-Json;
}
catch {
 throw $_;
}