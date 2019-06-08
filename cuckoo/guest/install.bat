@echo off 
::SCRIPT TO INSTALL CUCKOO VM GUEST -- use VMCLOAK knowledge 
::verify admin access
::reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f
::After UAC disable you must reboot and rerun the script
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

::keyboard
echo "Configure keyboard"
control intl.cpl,, /f:"%~dp0\conf\keyboard.xml"

echo "Configure network"
echo "Setting Static IP Information" 
::configure network interface
netsh interface ip set address "Local Area Connection" static 192.168.56.10 255.255.255.0 192.168.56.1
::configure DNS
netsh interface ip set dns "Local Area Connection" static 192.168.56.1
::disable firewall windows
NetSh Advfirewall set allprofiles state off
::print interface configuration
netsh int ip show config 

::install python && pip & PILLOW & cuckoo
::check arch
IF EXIST "C:\Program Files (x86)" (
::set ARCH=64
echo "Install Python: %~dp0\softwares\python-2.7.16.amd64.msi"
msiexec /qn /i %~dp0\softwares\python-2.7.16.amd64.msi TARGETDIR=C:\Python27
) ELSE (
::set ARCH=86
echo "Install Python: %~dp0\softwares\python-2.7.16.msi"
msiexec /qn /i %~dp0\softwares\python-2.7.16.msi TARGETDIR=C:\Python27
)
echo "Install PIP"
C:\Python27\python %~dp0\softwares\get-pip.py
echo "Install Pillow"
C:\Python27\python -m pip install Pillow
echo "Install Cuckoo agent"
copy %~dp0\softwares\agent.py c:\agent.py
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run" /v Agent /t REG_SZ /d "python c:\agent.py" /f

::dotnet && wic && logging powershell
echo "Install WIC"
IF EXIST "C:\Program Files (x86)" (
::set ARCH=64
%~dp0\softwares\wic_x64_enu.exe /passive /norestart
sc config wuauserv start= auto
wusa.exe %~dp0\softwares\Windows6.1-KB2819745-x64-MultiPkg.msu /quiet /norestart
wusa.exe %~dp0\softwares\Windows6.1-KB3109118-v4-x64.msu /quiet /norestart
sc config wuauserv start= disabled
net stop wuauserv
) ELSE (
::set ARCH=86
%~dp0\softwares\wic_x86_enu.exe /passive /norestart
sc config wuauserv start= auto
wusa.exe %~dp0\softwares\Windows6.1-KB2819745-x86-MultiPkg.msu /quiet /norestart
wusa.exe %~dp0\softwares\Windows6.1-KB3109118-v4-x86.msu /quiet /norestart
sc config wuauserv start= disabled
net stop wuauserv
)
echo "Install Dotnet"
%~dp0\softwares\dotNetFx40_Full_x86_x64.exe /passive /norestart
echo "Install Patch KB3102436"
%~dp0\softwares\NDP461-KB3102436-x86-x64-AllOS-ENU.exe /passive /norestart
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" /v EnableModuleLogging /t REG_DWORD /d 00000001 /f /reg:64
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" /v * /t REG_SZ /d * /f /reg:64
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" /v EnableScriptBlockLogging /t REG_DWORD /d 00000001 /f /reg:64
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription" /v EnableTranscripting /t REG_DWORD /d 00000001 /f /reg:64
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription" /v OutputDirectory /t REG_SZ /d \C:\PSTranscipts\/f /reg:64
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription" /v EnableInvocationHeader /t REG_DWORD /d 00000001 /f /reg:64

::java
echo "Install Java"
%~dp0\softwares\jdk-7-windows-i586.exe /s
IF EXIST "C:\Program Files (x86)" (
::set ARCH=64
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\JavaSoft\Java Update\Policy" /v EnableJavaUpdate /t REG_DWORD /d 0 /f
) 
::change C:\Windows\Sun\Java\Deployment\deployment.properties
::change C:\Windows\Sun\Java\Deployment\deployment.config
::https://stackoverflow.com/questions/127318/is-there-any-sed-like-utility-for-cmd-exe 

::flash
echo "Install Flash"
msiexec /qn /i %~dp0\softwares\flashplayer11_7r700_169_winax.msi /passive
timeout 20 > NUL
(echo SilentAutoUpdateEnable=0)>> "C:\Windows\System32\Macromed\Flash\mms.cfg"
(echo AutoUpdateDisable=1)>> "C:\Windows\System32\Macromed\Flash\mms.cfg"
(echo ProtectedMode=0)>> "C:\Windows\System32\Macromed\Flash\mms.cfg"

::pdf reader
echo "Install PDF reader"
%~dp0\softwares\AdbeRdr90_en_US.exe /sAll /msi /norestart /passive ALLUSERS=1 EULA_ACCEPT=YES
reg add "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\AdobeViewer" /v EULA /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\Software\WOW6432Node\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\AdobeViewer" /v Launched /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\AVGeneral" /v bCheckForUpdatesAtStartup /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\FeatureLockDown" /v bUpdater /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\FeatureLockDown" /v bProtectedMode /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\FeatureLockDown" /v iProtectedView /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\FeatureLockDown" /v bEnhancedSecurityStandalone /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\FeatureLockDown" /v bEnhancedSecurityInBrowser /t REG_DWORD /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\TrustManager\cDefaultLaunchURLPerms" /v iURLPerms /t REG_DWORD /d 2 /f 
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\FeatureLockDown\cDefaultLaunchURLPerms" /v iUnknownURLPerms /t REG_DWORD /d 2 /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\FeatureLockDown\cDefaultLaunchAttachmentPerms" /v tBuiltInPermList /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\FeatureLockDown\cDefaultLaunchAttachmentPerms" /v iUnlistedAttachmentTypePerm /t REG_DWORD /d 2 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\FeatureLockDown" /v bEnableFlash /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Adobe\Acrobat Reader\CHANGE_BY_VERSION_ADOBE\Security\cDigSig\cCustomDownload" /v bLoadSettingsFromURL /t REG_DWORD /d 0 /f

::firefox
echo "Install Firefox"
%~dp0\softwares\Firefox_Setup_41.0.2.exe -ms

::winrar
echo "Install Winrar"
IF EXIST "C:\Program Files (x86)" (
%~dp0\softwares\winrar-x64-531.exe /S
) ELSE (
%~dp0\softwares\wrar531.exe /S
)

::office
::TODO

::instal mitm cert
echo "Install CERT MITM"
::certutil.exe -importpfx Root %~dp0\mitmproxy-ca-cert.p12
certutil.exe -addstore "Root" "%~dp0\mitmproxy-ca-cert.cer"

::IE11 CONF
echo "Configure IE11"
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main" /v DisableFirstRunCustomize /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Main" /v RunOnceComplete /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Main" /v RunOnceHasShown /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Main" /v EnableAutoUpgrade /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\0" /v 2500 /t REG_DWORD /d 3 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1" /v 2500 /t REG_DWORD /d 3 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v 2500 /t REG_DWORD /d 3 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v 2500 /t REG_DWORD /d 3 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4" /v 2500 /t REG_DWORD /d 3 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main" /v Isolation /t REG_SZ /d "PMIL" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_LOCALMACHINE_LOCKDOWN" /v "iexplore.exe" /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_RESTRICT_FILEDOWNLOAD" /v "iexplore.exe" /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main\Security" /v DisableFixSecuritySettings /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main\Security" /v DisableSecuritySettingsCheck /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\PhishingFilter" /v EnabledV8 /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\PhishingFilter" /v EnabledV9 /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main" /v "Check_Associations" /t REG_SZ /d "no" /f
reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "about:blank" /f

::install SYSMON -- https://download.sysinternals.com/files/Sysmon.zip (last install for avoid noise log)
echo "Install Sysmon"
IF EXIST "C:\Program Files (x86)" (
%~dp0\softwares\sysmon64.exe -accepteula -i %~dp0\conf\sysmon.xml
) ELSE (
%~dp0\softwares\sysmon.exe -accepteula -i %~dp0\conf\sysmon.xml
)
echo "You must install office manually!"
set /p DUMMY=Press "ENTER" for finish...

::antivm detection
::https://github.com/nsmfoo/antivmdetection && http://blog.prowling.nu/2012/08/modifying-virtualbox-settings-for.html && http://blog.michaelboman.org/2014/01/making-virtualbox-nearly-undetectable.html
