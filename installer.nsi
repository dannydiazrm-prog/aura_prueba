!include "MUI2.nsh"

Name "Aura Estandar"
OutFile "Instalador_Aura_Estandar.exe"
InstallDir "$PROGRAMFILES\AuraEstandar"

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Spanish"

Section "Instalar App"
    SetOutPath "$INSTDIR"
    
    # Copiamos el ejecutable y las librerías DLL usando barras de Windows (\)
    File "build\windows\x64\runner\Release\domis_estandar.exe"
    File "build\windows\x64\runner\Release\*.dll"
    
    # Copiamos la carpeta data entera de forma recursiva
    File /r "build\windows\x64\runner\Release\data"

    # Acceso directo en el escritorio
    CreateShortCut "$DESKTOP\Aura Estandar.lnk" "$INSTDIR\domis_estandar.exe"
    
    # Desinstalador
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
    Delete "$DESKTOP\Aura Estandar.lnk"
    RMDir /r "$INSTDIR"
SectionEnd
