@echo off 
::SCRIPT TO INSTALL CUCKOO VM GUEST -- use VMCLOAK knowledge 
::verify admin access
::reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f
::After UAC disable you must reboot and rerun the script
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

for /F "tokens=*" %1 in ('wevtutil.exe el') DO wevtutil.exe cl "%1"
