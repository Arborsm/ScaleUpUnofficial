@echo off
setlocal

echo.
echo Cleaning previous build artifacts...
CALL flutter clean
IF %ERRORLEVEL% NEQ 0 (
    echo "flutter clean failed! Aborting."
    goto :eof
)

echo.
echo Getting dependencies...
CALL flutter pub get
IF %ERRORLEVEL% NEQ 0 (
    echo "flutter pub get failed! Aborting."
    goto :eof
)

echo.
echo Starting release build for Windows desktop...
echo This may take a few minutes.
echo.

CALL flutter build windows ^
  --release ^
  --obfuscate ^
  --split-debug-info=build/debug-info ^
  --tree-shake-icons

IF %ERRORLEVEL% NEQ 0 (
    echo "flutter build failed! Check the error messages above."
    goto :eof
)

echo.
echo -------------------------------------
echo  Build finished successfully!
echo -------------------------------------
echo.
echo Find the release executable in: build\windows\runner\Release
echo Find the de-obfuscation symbols in: build\debug-info\
echo.

:eof
pause
endlocal