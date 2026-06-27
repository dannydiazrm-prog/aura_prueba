!include "MUI2.nsh"

Name "Aura Demo"
OutFile "Instalador_Aura_Prueba.exe"
InstallDir "$PROGRAMFILES\AuraDemo"

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Spanish"

Section "Instalar App"
    SetOutPath "$INSTDIR"
    File "build\windows\x64\runner\Release\*.exe"
    File "build\windows\x64\runner\Release\*.dll"
    File /r "build\windows\x64\runner\Release\data"
    CreateShortCut "$DESKTOP\Aura Demo.lnk" "$INSTDIR\aura_prueba.exe"
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
    Delete "$DESKTOP\Aura Demo.lnk"
    RMDir /r "$INSTDIR"
SectionEnd