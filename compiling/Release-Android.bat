@echo off

cd C:\Users\Timeless\Desktop\Timeless-Engine-main

echo ===================================================
echo [Timeless Engine] Cleaning lime cache...
echo ===================================================
call lime clean android

echo.
echo ===================================================
echo [Timeless Engine] Compiling...
echo ===================================================
call lime build android

echo.
echo ===================================================
echo [Timeless Engine] ERROR
echo ===================================================
pause
