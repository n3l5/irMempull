IR Memory pull (irMempull)

DESCRIPTION:

irMempull is a PowerShell script utilized to pull memory from a live system. Tested on Windows 7, 8, Server 2008, and Server 2012 systems. 

It utilizes the WinPMEM memory dumping tool to dump memory.

NOTEs: 
- All testing done on PowerShell v4
- Requires WinPMEM.exe (from Rekall Memory Forensic Toolkit)
- Requires 7za.exe (7zip cmd line) for compression w/ password protection
	
Assumed Directories:
- c:\windows\temp\IR - Where the work will be done on target (no need to create)
		
***As expected: Must be ran a user that will have Admin creds on the remote system. The assumption is that the target system is part of a domain, but not required.
	
LINKs:  
	
irMempull main - https://github.com/n3l5/irMempull
	
Links to required tools:
- WinPMEM.exe - via Rekall Memory Forensic Toolkit - http://www.rekall-forensic.com/downloads/WinPMEM/
- 7za.exe - Part of the 7-Zip archiver, 7za can be downloaded from here: http://www.7-zip.org/
	
Various tools for analysis of the artifacts:
- Rekall Memory Forensic Toolkit - http://www.rekall-forensic.com/index.html
- Volatility - http://www.volatilityfoundation.org/
- Mandiant Redline - https://www.mandiant.com/resources/download/redline
