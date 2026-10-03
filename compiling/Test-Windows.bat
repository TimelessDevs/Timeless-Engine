@echo off

cd C:\Users\Timeless\Desktop\Timeless-Engine-main

echo ===================================================
echo [Timeless Engine] Cleaning lime cache...
echo ===================================================
call lime clean windows

echo.
echo ===================================================
echo [Timeless Engine] Compiling...
echo ===================================================
call lime test windows -32

echo.
echo ===================================================
echo [Timeless Engine] ERROR.
echo ===================================================
pause
