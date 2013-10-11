<#  
.SYNOPSIS  
    
.DESCRIPTION

#>

echo "=============================================="
echo "=============================================="
Write-Host -Fore Magenta "

  _      __  __                            _ _ 
 (_)    |  \/  |                          | | |
  _ _ __| \  / | ___ _ __ ___  _ __  _   _| | |
 | | '__| |\/| |/ _ \ '_ ` _ \| '_ \| | | | | |
 | | |  | |  | |  __/ | | | | | |_) | |_| | | |
 |_|_|  |_|  |_|\___|_| |_| |_| .__/ \__,_|_|_|
                              | |              
                              |_|              

 "
echo "=============================================="
Write-Host -Fore Yellow "Run as administrator/elevated privileges!!!"
echo "=============================================="
echo ""


Write-Host -Fore Cyan ">>>>> Press a key to begin...."
[void][System.Console]::ReadKey($TRUE)
echo ""
echo ""
$userDom = Read-Host "Enter your target DOMAIN (if any)..."
$username = Read-Host "Enter you UserID..."
$combCred = "$userDom" + "\$username"
$cred = Get-Credential $combCred
$target = read-host ">>>>> Please enter a HOSTNAME or IP..."
$irFolder = "c:\Windows\Temp\IR\"
echo ""
Write-Host -Fore Yellow ">>>>> pinging $target...."
echo ""
c:\TOOLS\tcping.exe -s -i 10 -r 10 $target 445
echo ""
echo "=============================================="

$targetName = Get-WMIObject Win32_ComputerSystem -ComputerName $target -Credential $cred | ForEach-Object Name
$targetIP = Get-WMIObject -Class Win32_NetworkAdapterConfiguration -ComputerName $target -Filter "IPEnabled='TRUE'" | Where {$_.IPAddress} | Select -ExpandProperty IPAddress | Where{$_ -notlike "*:*"}
Write-Host -ForegroundColor Magenta "==[ $targetName - $targetIP ]=="

################
##Set up environment on remote system. IR folder for tools and art folder for artifacts.##
################
##For consistency, the working directory will be located in the "c:\windows\temp\IR" folder on both the target and initiator system.
##Tools will stored directly in the "IR" folder for use. Artifacts collected on the local environment of the remote system will be dropped in the workingdir.

##Determine x32 or x64
$arch = Get-WmiObject -Class Win32_Processor -ComputerName $target -Credential $cred | foreach {$_.AddressWidth}

#Determine XP or Win7
$OSvers = Get-WMIObject -Class Win32_OperatingSystem -ComputerName $target -Credential $cred | foreach {$_.Version}
	if ($OSvers -like "5*"){
	Write-Host -ForegroundColor Magenta "==[ Host OS: Windows XP $arch  ]=="
	}
	if ($OSvers -like "6*"){
	Write-Host -ForegroundColor Magenta "==[ Host OS: Windows 7 $arch    ]=="
	}
echo "=============================================="
echo ""
##Set up PSDrive mapping to remote drive
New-PSDrive -Name X -PSProvider filesystem -Root \\$target\c$ -Credential $cred | Out-Null

$remoteIRfold = "X:\windows\Temp\IR"
$date = Get-Date -format yyyy-MM-dd_HHmm_
$irFolder = "c:\Windows\Temp\IR\"
$artFolder = $date + $targetName
$workingDir = $irFolder + $artFolder
$dirList = ("$remoteIRfold\$artFolder")
New-Item -Path $dirList -ItemType Directory | Out-Null

##connect and move software to target client
Write-Host -Fore Green "Copying tools...."
$tool = "C:\TOOLS\winpmem\winpmem_1.4.exe"
Copy-Item $tool $remoteIRfold -recurse

$Memdump = "cmd /c c:\windows\temp\ir\winpmem_1.4.exe c:\windows\temp\ir\physmem.raw"
InVoke-WmiMethod -class Win32_process -name Create -ArgumentList $memdump -ComputerName $target -Credential $cred | Out-Null
do {(Write-Host -ForegroundColor Yellow "  memory copy to complete..."),(Start-Sleep -Seconds 30)}
until ((Get-WMIobject -Class Win32_process -Filter "Name='winpmem_1.4.exe'" -ComputerName $target -Credential $cred | where {$_.Name -eq "winpmem_1.4.exe"}).ProcessID -eq $null)
}
Write-Host "  [done]"

###################
##Package up the data and pull
###################
echo ""
echo "=============================================="
Write-Host -Fore Magenta ">>>[Packaging the collection]<<<"
echo "=============================================="
echo ""

##7zip the artifact collection##
$passwd = read-host ">>>>> Please supply a password"
$7z = "cmd /c c:\Windows\temp\IR\7za.exe a $workingDir.7z -p$passwd -mhe $workingDir_memdump -y > null"
InVoke-WmiMethod -class Win32_process -name Create -ArgumentList $7z -ComputerName $target -Credential $cred | Out-Null
do {(Write-Host -ForegroundColor Yellow "  packing the collected artifacts..."),(Start-Sleep -Seconds 10)}
until ((Get-WMIobject -Class Win32_process -Filter "Name='7za.exe'" -ComputerName $target -Credential $cred | where {$_.Name -eq "7za.exe"}).ProcessID -eq $null)
Write-Host -ForegroundColor Yellow "  Packing complete..."

##size it up
Write-Host -ForegroundColor Cyan "  [Package Stats]"
$dirsize = "{0:N2}" -f ((Get-ChildItem $remoteIRfold\$artFolder | Measure-Object -property length -sum ).Sum / 1MB) + " MB"
Write-Host -ForegroundColor Cyan "  Working Dir: $dirsize "
$7zsize = "{0:N2}" -f ((Get-ChildItem $remoteIRfold\$artfolder.7z | Measure-Object -property length -sum ).Sum / 1MB) + " MB"
Write-Host -ForegroundColor Cyan "  Package size: $7zsize "

Write-Host -Fore Green "Transfering the package...."
Move-Item $remoteIRfold\$artfolder_memdump.7z $irFolder
Write-Host -Fore Yellow "  [done]"

###Delete the IR folder##
Write-Host -Fore Green "Removing the working environment...."
Remove-Item $remoteIRfold -Recurse -Force 

##Disconnect the PSDrive X mapping##
Remove-PSDrive X

##Ending##
echo "=============================================="
Write-Host -ForegroundColor Magenta ">>>>>>>>>>[[ irMemPull complete ]]<<<<<<<<<<<"
echo "=============================================="
