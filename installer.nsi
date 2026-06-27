!include "MUI2.nsh"

Name "Aura Estandar"
OutFile "Instalador_Aura_Estandar.exe"
InstallDir "$PROGRAMFILES\AuraEstandar"

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Spanish"

Section "Instalar App"
    SetOutPath "$INSTDIR"
    File "build\windows\x64\runner\Release\*.exe"
    File "build\windows\x64\runner\Release\*.dll"
    File /r "build\windows\x64\runner\Release\data"
    CreateShortCut "$DESKTOP\Aura Estandar.lnk" "$INSTDIR\domis_estandar.exe"
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
    Delete "$DESKTOP\Aura Estandar.lnk"
    RMDir /r "$INSTDIR"
SectionEnd
