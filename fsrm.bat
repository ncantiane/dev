::	Copiez fsrm.bat & authftp.txt sur C:\							::
::	Lancez fsrm.bat via PowerShell avec en argument le dossier que vous voulez protéger	::
::	Ver : 0.1 Beta Echo Tango Alpha								::

@echo off

Setlocal

:: Connaitre version Windows

For /f "tokens=2 delims=[]" %%G in ('ver') Do (set _version=%%G) 

For /f "tokens=2,3,4 delims=. " %%G in ('echo %_version%') Do (set _major=%%G& set _minor=%%H& set _build=%%I) 

Echo Release version : %_major%,%_minor%

if "%_major%"=="6" goto tutu

Echo Pas bon du tout ! Appeler ASM ou DR pour changer serveur !

goto:fin

:tutu

if "%_minor%"=="0" goto W2008
if "%_minor%"=="1" goto W2008
if "%_minor%"=="2" goto W2012
if "%_minor%"=="3" goto W2012

Echo Connais pas cette version de Windows.... :(

goto:fin

:W2008

:: Installation du role FSRM

servermanagercmd.exe -install "FS-Resource-Manager"

:: Téléchargement des fichiers via ftp

ftp -s:authftp.txt -n

:: Import du groupe de fichiers

filescrn filegroup import /file:listcrypto.xml

:: Création du modèle de filtre

filescrn template add /template:bloquer_crypto /add-filegroup:crypto /type:active /add-notification:e,notif_event.txt /add-notification:c,notif_popup.txt

:: Création du filtre

filescrn screen add /path:%1 /type:active /add-filegroup:"crypto" /add-notification:e,notif_event.txt /add-notification:c,notif_popup.txt

:: Suppression des fichiers

del listcrypto.xml
del notif_event.txt
del notif_popup.txt

goto:fin

:W2012

:: Installation du role FSRM

Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools

:: Téléchargement des fichiers via ftp

ftp -s:authftp.txt -n

:: Import du groupe de fichiers

filescrn filegroup

:: Création du modèle de filtre

filescrn template

:: Création du filtre

filescrn screen
:: Suppression des fichiers

del listcrypto.xml
del notif_event.txt
del notif_popup.txt

goto:fin

:fin

Echo Fini !!!

pause
