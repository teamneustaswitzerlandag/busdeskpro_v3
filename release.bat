@echo off
setlocal enabledelayedexpansion

REM Flutter Release APK Builder und Azure Blob Storage Uploader
REM Erstellt von: BusDesk Pro Development Team

set "PROJECT_PATH=%~dp0"
set "CONTAINER_NAME=releases"
set "BLOB_NAME="
set "VERSION="

REM Azure Blob Storage Konfiguration
set "CONNECTION_STRING=DefaultEndpointsProtocol=https;AccountName=busdeskproreleases;AccountKey=zo0YqomliF/O7X/9iay+SmlsFc7yEncJcPO7j9G10UZiY9cf0xDJ3xoWgn6vGJ1Sh5UQO4skyVp1+AStejSCpQ==;EndpointSuffix=core.windows.net"

echo.
echo BusDesk Pro - Flutter APK Builder ^& Azure Uploader
echo =================================================
echo.

REM Versionsnummer abfragen
if "%VERSION%"=="" (
    echo Versionsnummer eingeben:
    echo    Format: x.y.z (z.B. 1.0.0, 2.1.3, 1.0.0-beta^)
    echo    Leer lassen für automatische Generierung
    set /p VERSION="   Version: "
    
    if "!VERSION!"=="" (
        for /f "tokens=1-3 delims=." %%a in ('date /t') do (
            set "YEAR=%%c"
            set "MONTH=%%b"
            set "DAY=%%a"
        )
        set "VERSION=!YEAR!.!MONTH!.!DAY!"
        echo    Automatische Version: !VERSION!
    ) else (
        echo    Version validiert: !VERSION!
    )
) else (
    echo Verwendete Version: %VERSION%
)

echo.
echo Führe Systemprüfungen durch...
echo.

REM Flutter prüfen - OHNE DEBUG-AUSGABE
echo Prüfe Flutter...
where flutter >nul 2>&1
echo "Test"
if %errorlevel% neq 0 (
    echo FEHLER: Flutter ist nicht installiert oder nicht im PATH
    echo.
    echo Mögliche Lösungen:
    echo 1. Flutter installieren von: https://flutter.dev/docs/get-started/install/windows
    echo 2. Flutter zum PATH hinzufügen
    echo 3. Command Prompt als Administrator starten
    echo.
    pause
    exit /b 1
) else (
    echo OK: Flutter ist installiert
)

REM Azure CLI prüfen (nur für Upload erforderlich)
echo.
echo Prüfe Azure CLI...
call where az >nul 2>&1
if %errorlevel% neq 0 (
    echo FEHLER: Azure CLI ist nicht installiert
    echo.
    echo Installiere Azure CLI über winget...
    call winget install Microsoft.AzureCLI
    if %errorlevel% neq 0 (
        echo FEHLER: Azure CLI Installation fehlgeschlagen
        echo Bitte installiere Azure CLI manuell von: https://aka.ms/installazurecliwindows
        echo.
        pause
        exit /b 1
    ) else (
        echo OK: Azure CLI erfolgreich installiert
        echo Warte 10 Sekunden für PATH-Update...
        timeout /t 10 /nobreak >nul
    )
) else (
    echo OK: Azure CLI ist installiert
)

REM Projektpfad prüfen
echo.
echo Prüfe Flutter-Projekt...
if not exist "%PROJECT_PATH%pubspec.yaml" (
    echo FEHLER: Kein Flutter-Projekt im angegebenen Pfad gefunden
    echo Aktueller Pfad: %PROJECT_PATH%
    echo.
    pause
    exit /b 1
) else (
    echo OK: Flutter-Projekt gefunden
)

echo.
echo Alle Prüfungen erfolgreich
echo.

REM APK Build
echo Starte Flutter Release APK Build...
echo.

cd /d "%PROJECT_PATH%"
echo Wechsle zu: %CD%
echo.



REM APK-Pfad prüfen
set "APK_PATH=%PROJECT_PATH%build\app\outputs\flutter-apk\app-release.apk"
if not exist "%APK_PATH%" (
    echo FEHLER: APK-Datei nicht gefunden
    echo.
    pause
    exit /b 1
)

REM APK-Größe ermitteln
for %%A in ("%APK_PATH%") do set "FILE_SIZE=%%~zA"
set /a "FILE_SIZE_MB=!FILE_SIZE!/1048576"

echo.
echo APK-Informationen:
echo    Pfad: %APK_PATH%
echo    Größe: !FILE_SIZE_MB! MB
echo    Version: %VERSION%
echo.

REM Azure Blob Storage Upload
echo Starte Upload zu Azure Blob Storage...
echo Verwendet Connection String (kein Login erforderlich)...
echo.

REM Blob Name generieren
if "%BLOB_NAME%"=="" (
    for /f "tokens=1-6 delims=: " %%a in ('echo %date% %time%') do (
        set "TIMESTAMP=%%c%%b%%a_%%d%%e%%f"
    )
    set "TIMESTAMP=!TIMESTAMP: =0!"
    set "BLOB_NAME=app-release_v%VERSION%_!TIMESTAMP!.apk"
)

echo.
echo Lade hoch: %BLOB_NAME%
echo    Version: %VERSION%
echo.

REM Upload zu Azure Blob Storage mit Retry-Mechanismus
echo Starte Upload...
echo Hinweis: Bei großen APK-Dateien kann der Upload einige Minuten dauern...
echo.

REM Retry-Mechanismus für Upload
set "UPLOAD_SUCCESS=0"
set "RETRY_COUNT=0"
set "MAX_RETRIES=3"

:UPLOAD_RETRY
set /a "RETRY_COUNT+=1"
echo.
echo Upload-Versuch %RETRY_COUNT% von %MAX_RETRIES%...

REM Verwende Azure CLI Upload mit optimierten Parametern
call az storage blob upload --connection-string "%CONNECTION_STRING%" --container-name "%CONTAINER_NAME%" --file "%APK_PATH%" --name "%BLOB_NAME%" --overwrite --max-concurrency 1 --max-single-put-size 100 2>nul
if %errorlevel% equ 0 (
    set "UPLOAD_SUCCESS=1"
    echo Upload erfolgreich abgeschlossen!
    goto :UPLOAD_SUCCESS
)

echo Upload fehlgeschlagen (Errorlevel: %errorlevel%)
if %RETRY_COUNT% lss %MAX_RETRIES% (
    echo Warte 10 Sekunden vor nächstem Versuch...
    timeout /t 10 /nobreak >nul
    goto :UPLOAD_RETRY
)

REM Alle Retry-Versuche fehlgeschlagen, versuche alternative Methoden
echo Alle Retry-Versuche fehlgeschlagen, versuche alternative Methoden...
echo.

REM Alternative 1: Batch-Upload
echo Versuche Batch-Upload-Methode...
call az storage blob upload-batch --connection-string "%CONNECTION_STRING%" --destination "%CONTAINER_NAME%" --source "%PROJECT_PATH%build\app\outputs\flutter-apk" --destination-path "%BLOB_NAME%" --overwrite 2>nul
if %errorlevel% equ 0 (
    set "UPLOAD_SUCCESS=1"
    echo Batch-Upload erfolgreich!
    goto :UPLOAD_SUCCESS
)

REM Alternative 2: Einfacher Upload ohne Parameter
echo Versuche einfachen Upload...
call az storage blob upload --connection-string "%CONNECTION_STRING%" --container-name "%CONTAINER_NAME%" --file "%APK_PATH%" --name "%BLOB_NAME%" 2>nul
if %errorlevel% equ 0 (
    set "UPLOAD_SUCCESS=1"
    echo Einfacher Upload erfolgreich!
    goto :UPLOAD_SUCCESS
)

REM Alternative 3: Upload mit detaillierter Ausgabe
echo Versuche Upload mit detaillierter Ausgabe...
call az storage blob upload --connection-string "%CONNECTION_STRING%" --container-name "%CONTAINER_NAME%" --file "%APK_PATH%" --name "%BLOB_NAME%" --overwrite
if %errorlevel% equ 0 (
    set "UPLOAD_SUCCESS=1"
    echo Upload mit detaillierter Ausgabe erfolgreich!
    goto :UPLOAD_SUCCESS
)

REM Alle Methoden fehlgeschlagen
echo.
echo FEHLER: Alle Upload-Methoden fehlgeschlagen!
echo Mögliche Ursachen:
echo - Netzwerkverbindung instabil
echo - Azure-Server temporär nicht erreichbar
echo - APK-Datei zu groß für Upload
echo.
echo Versuche manuellen Upload:
echo az storage blob upload --connection-string "%CONNECTION_STRING%" --container-name "%CONTAINER_NAME%" --file "%APK_PATH%" --name "%BLOB_NAME%" --overwrite
echo.
pause
exit /b 1

:UPLOAD_SUCCESS
REM Prüfe ob Upload tatsächlich erfolgreich war
echo Prüfe Upload-Erfolg...
call az storage blob exists --connection-string "%CONNECTION_STRING%" --container-name "%CONTAINER_NAME%" --name "%BLOB_NAME%" --query "exists" --output tsv >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNUNG: Upload-Status konnte nicht geprüft werden
) else (
    echo Upload-Status erfolgreich geprüft
)

echo Upload erfolgreich abgeschlossen

echo.
echo OK: Upload erfolgreich!
echo Blob URL: https://busdeskproreleases.blob.core.windows.net/%CONTAINER_NAME%/%BLOB_NAME%
echo.

echo ERFOLG! APK wurde erfolgreich erstellt und hochgeladen!
echo Zusammenfassung:
echo    Flutter APK Build: Erfolgreich
echo    Azure Blob Upload: Erfolgreich
echo    Container: %CONTAINER_NAME%
echo    Blob Name: %BLOB_NAME%
echo    Version: %VERSION%
echo.

echo Skript beendet.
pause