@echo off
setlocal ENABLEDELAYEDEXPANSION

rem =====================================
rem  Paths
rem =====================================

rem Directory this script lives in (repo root)
set REPO_ROOT=%~dp0
if "%REPO_ROOT:~-1%"=="\" set REPO_ROOT=%REPO_ROOT:~0,-1%

set TOOLCHAIN=%REPO_ROOT%\Toolchain
set MINGW32=%TOOLCHAIN%\mingw32
set PYENV=%TOOLCHAIN%\python
set PYSCRIPTS=%PYENV%\Scripts

set BUILD_DIR=%REPO_ROOT%\build.w32
set INSTALL_PREFIX=%REPO_ROOT%\BuiltDLLs

echo Repo root:       %REPO_ROOT%
echo Toolchain root:  %TOOLCHAIN%
echo Build dir:       %BUILD_DIR%
echo Install prefix:  %INSTALL_PREFIX%
echo.

rem =====================================
rem  Sanity checks
rem =====================================

if not exist "%MINGW32%\bin\i686-w64-mingw32-gcc.exe" (
    echo [ERROR] %MINGW32%\bin\i686-w64-mingw32-gcc.exe not found.
    echo         Make sure your MinGW32 toolchain is under Toolchain\mingw32\bin.
    goto :end_fail
)

if not exist "%MINGW32%\include" (
    echo [ERROR] %MINGW32%\include not found.
    echo         Make sure mingw32\include is under Toolchain\mingw32\include.
    goto :end_fail
)

if not exist "%MINGW32%\lib" (
    echo [ERROR] %MINGW32%\lib not found.
    echo         Make sure mingw32\lib is under Toolchain\mingw32\lib.
    goto :end_fail
)

if not exist "%PYSCRIPTS%\python.exe" (
    echo [ERROR] %PYSCRIPTS%\python.exe not found.
    echo         Create a venv with:
    echo           py -3 -m venv Toolchain\python
    echo           Toolchain\python\Scripts\python.exe -m pip install meson ninja
    goto :end_fail
)

if not exist "%PYSCRIPTS%\meson.exe" (
    echo [ERROR] %PYSCRIPTS%\meson.exe not found.
    echo         Install Meson into the venv:
    echo           Toolchain\python\Scripts\python.exe -m pip install meson
    goto :end_fail
)

if not exist "%PYSCRIPTS%\ninja.exe" (
    echo [ERROR] %PYSCRIPTS%\ninja.exe not found.
    echo         Install Ninja into the venv:
    echo           Toolchain\python\Scripts\python.exe -m pip install ninja
    goto :end_fail
)

rem =====================================
rem  PATH so the local toolchain is used instead of requiring user to waste time installing atrocious shit piss mingw and libs manually
rem  Like c'mon bro I'm not a sadistic psycho to make people waste time on that crap. Who tf plays games on linux anyways, just sybao.
rem =====================================

set PATH=%MINGW32%\bin;%PYSCRIPTS%;%PATH%

echo PATH configured to use Toolchain compiler and venv tools first.
echo.

rem =====================================
rem  Clean previous build dir
rem =====================================

if exist "%BUILD_DIR%" (
    echo Cleaning old build dir "%BUILD_DIR%" ...
    rmdir /s /q "%BUILD_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to remove old build directory.
        goto :end_fail
    )
)

rem Ensure install prefix exists
if not exist "%INSTALL_PREFIX%" (
    mkdir "%INSTALL_PREFIX%"
)

rem =====================================
rem  Configure Meson (more like ButtPlugson like bro you could just ask me to build the thing using assembly at that point why bother)
rem =====================================

cd /d "%REPO_ROOT%"
echo Running Meson setup...
echo.

"%PYSCRIPTS%\meson.exe" setup ^
    "%BUILD_DIR%" ^
    --cross-file "%REPO_ROOT%\build-win32.txt" ^
    --buildtype=release ^
    --prefix "%INSTALL_PREFIX%" ^
    -Dstrip=false

if errorlevel 1 (
    echo.
    echo [ERROR] Meson configuration failed.
    goto :end_fail
)

rem =====================================
rem  Build + install with Ninja
rem =====================================

echo.
echo Running Ninja build and install...
echo.

"%PYSCRIPTS%\ninja.exe" -C "%BUILD_DIR%" install

if errorlevel 1 (
    echo.
    echo [ERROR] Ninja build or install failed.
    goto :end_fail
)

echo.
echo ======================================
echo  Build complete!
echo  DLLs should be under:
echo    %INSTALL_PREFIX%\x32
echo ======================================
echo.

goto :end_ok

rem =====================================
rem  End labels (both keep window open)
rem =====================================

:end_fail
echo.
echo Build FAILED. See messages above.
echo.
pause
goto :eof

:end_ok
pause
goto :eof
