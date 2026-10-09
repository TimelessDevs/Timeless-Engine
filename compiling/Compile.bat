@echo off
chcp 65001 > nul

cd /d "%~dp0.."

echo ===================================================
echo [Timeless Engine] Choose platform:
echo ===================================================
echo 1 - Windows
echo 2 - Android
echo 3 - iOS
echo 4 - Mac
echo 5 - Linux
echo.

set /p platform_choice="Choose platform (1-5): "

if "%platform_choice%"=="1" set "target_platform=windows"
if "%platform_choice%"=="2" set "target_platform=android"
if "%platform_choice%"=="3" set "target_platform=ios"
if "%platform_choice%"=="4" set "target_platform=mac"
if "%platform_choice%"=="5" set "target_platform=linux"

if not defined target_platform (
    echo No such target.
    pause
    exit /b
)

echo.
echo ===================================================
echo [Timeless Engine] Choose build type:
echo ===================================================
echo 1 - test
echo 2 - release
echo.

set /p action_choice="Choose build type (1-2): "

if "%action_choice%"=="1" set "target_action=test"
if "%action_choice%"=="2" set "target_action=build"

if not defined target_action (
    echo No such target.
    pause
    exit /b
)

echo.
echo ===================================================
echo [Timeless Engine] Cleaning lime cache...
echo ===================================================
call lime clean %target_platform% > nul 2>&1

echo.
echo ===================================================
echo [Timeless Engine] Compiling...
echo ===================================================

set "LOG_FILE=%temp%\lime_build_log.txt"
if exist "%LOG_FILE%" del "%LOG_FILE%"

if "%target_platform%"=="windows" if "%target_action%"=="test" (
    start /b "" cmd /c "call lime test windows -32 > "%LOG_FILE%" 2>&1"
) else (
    start /b "" cmd /c "call lime %target_action% %target_platform% > "%LOG_FILE%" 2>&1"
)

setlocal enabledelayedexpansion
set "spin=\ ^| / -"

:loop
for %%a in (%spin%) do (
    tasklist /fi "imagename eq haxelib.exe" 2>nul | findstr /i "haxelib.exe" >nul
    set "hax_active=!errorlevel!"
    tasklist /fi "imagename eq cl.exe" 2>nul | findstr /i "cl.exe" >nul
    set "cl_active=!errorlevel!"
    tasklist /fi "imagename eq lime.exe" 2>nul | findstr /i "lime.exe" >nul
    set "lime_active=!errorlevel!"

    if !hax_active! equ 1 if !cl_active! equ 1 if !lime_active! equ 1 (
        timeout /t 1 /nobreak >nul
        goto compile_end
    )
    
    cls
    echo ===================================================
    echo [Timeless Engine] Compiling...
    echo ===================================================
    echo  [%%a] Compiling %target_action% for %target_platform%...
    timeout /t 1 /nobreak >nul
)
goto loop

:compile_end
cls
echo.
echo Done.

findstr /i /c:"error" /c:"failed" /c:"crit" "%LOG_FILE%" >nul
if %errorlevel% equ 0 (
    goto error
) else (
    goto success
)

:error
echo.
echo ===================================================
echo [Timeless Engine] Error.
echo ===================================================
type "%LOG_FILE%"
if exist "%LOG_FILE%" del "%LOG_FILE%"
goto end

:success
echo.
echo ===================================================
echo [Timeless Engine] Success.
echo ===================================================
if exist "%LOG_FILE%" del "%LOG_FILE%"
goto end

:end
pause
