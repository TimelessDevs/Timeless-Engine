@echo off

cd C:\Users\Timeless\Desktop\Timeless-Engine-main

echo ===================================================
echo [Timeless Engine] Cleaning lime cache...
echo ===================================================
call lime clean ios

echo.
echo ===================================================
echo [Timeless Engine] Compiling...
echo ===================================================
call lime test ios

echo.
echo ===================================================
echo [Timeless Engine] Build successful or stopped.
echo ===================================================
pause
