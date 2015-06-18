@echo off

rem ==========================================================================
rem Shortcuts for various tasks, emulating UNIX "make" on Windows.
rem It is primarly intended as a shortcut for compiling / installing
rem psutil ("make.bat build", "make.bat install") and running tests
rem ("make.bat test").
rem
rem This script is modeled after my Windows installation which uses:
rem - Visual studio 2008 for Python 2.6, 2.7, 3.2
rem - Visual studio 2010 for Python 3.3+
rem ...therefore it might not work on your Windows installation.
rem
rem By default C:\Python27\python.exe is used.
rem To compile for a specific Python version run:
rem     set PYTHON=C:\Python34\python.exe & make.bat build
rem
rem To use a different test script:
rem      set PYTHON=C:\Python34\python.exe & set TSCRIPT=foo.py & make.bat test
rem ==========================================================================

if "%PYTHON%" == "" (
    set PYTHON=C:\Python27\python.exe
)
if "%TSCRIPT%" == "" (
    set TSCRIPT=test\test_psutil.py
)

set PYTHON26=C:\Python26\python.exe
set PYTHON27=C:\Python27\python.exe
set PYTHON33=C:\Python33\python.exe
set PYTHON34=C:\Python34\python.exe
set PYTHON26-64=C:\Python26-64\python.exe
set PYTHON27-64=C:\Python27-64\python.exe
set PYTHON33-64=C:\Python33-64\python.exe
set PYTHON34-64=C:\Python34-64\python.exe

set ALL_PYTHONS=%PYTHON26% %PYTHON27% %PYTHON33% %PYTHON34% %PYTHON26-64% %PYTHON27-64% %PYTHON33-64% %PYTHON34-64%

rem Needed to locate the .pypirc file and upload exes on PYPI.
set HOME=%USERPROFILE%

rem ==========================================================================

if "%1" == "help" (
    :help
    echo Run `make ^<target^>` where ^<target^> is one of:
    echo   build         compile without installing
    echo   build-all     build exes + wheels
    echo   clean         clean build files
    echo   install       compile and install
    echo   setup-env     install pip, unittest2, wheels for all python versions
    echo   test          run tests
    echo   test-memleaks run memory leak tests
    echo   test-process  run process related tests
    echo   test-system   run system APIs related tests
    echo   uninstall     uninstall
    echo   upload-all    upload exes + wheels
    goto :eof
)

if "%1" == "clean" (
    for /r %%R in (__pycache__) do if exist %%R (rmdir /S /Q %%R)
    for /r %%R in (*.pyc) do if exist %%R (del /s %%R)
    for /r %%R in (*.pyd) do if exist %%R (del /s %%R)
    for /r %%R in (*.orig) do if exist %%R (del /s %%R)
    for /r %%R in (*.bak) do if exist %%R (del /s %%R)
    for /r %%R in (*.rej) do if exist %%R (del /s %%R)
    if exist psutil.egg-info (rmdir /S /Q psutil.egg-info)
    if exist build (rmdir /S /Q build)
    if exist dist (rmdir /S /Q dist)
    goto :eof
)

if "%1" == "build" (
    :build
    "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin\vcvars64.bat"
    %PYTHON% setup.py build
    if %errorlevel% neq 0 goto :error
	rem copies *.pyd files in ./psutil directory in order to allow
	rem "import psutil" when using the interactive interpreter from
    rem within this directory.
    %PYTHON% setup.py build_ext -i
    if %errorlevel% neq 0 goto :error
    goto :eof
)

if "%1" == "install" (
    :install
    call :build
    %PYTHON% setup.py install
    goto :eof
)

if "%1" == "uninstall" (
    for %%A in ("%PYTHON%") do (
        set folder=%%~dpA
    )
    for /F "delims=" %%i in ('dir /b %folder%\Lib\site-packages\*psutil*') do (
        rmdir /S /Q %folder%\Lib\site-packages\%%i
    )
    goto :eof
)

if "%1" == "test" (
    call :install
    %PYTHON% %TSCRIPT%
    goto :eof
)

if "%1" == "test-process" (
    call :install
    %PYTHON% -m unittest -v test.test_psutil.TestProcess
    goto :eof
)

if "%1" == "test-system" (
    call :install
    %PYTHON% -m unittest -v test.test_psutil.TestSystem
    goto :eof
)

if "%1" == "test-memleaks" (
    call :install
    %PYTHON% test\test_memory_leaks.py
    goto :eof
)

if "%1" == "build-all" (
    :build-all
    "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin\vcvars64.bat"
    for %%P in (%ALL_PYTHONS%) do (
        %%P setup.py build bdist_wininst || goto :error
        %%P setup.py build bdist_wheel || goto :error
    )
    echo OK
    goto :eof
)

if "%1" == "upload-all" (
    :upload-exes
    "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin\vcvars64.bat"
    for %%P in (%ALL_PYTHONS%) do (
        %%P setup.py build bdist_wininst upload || goto :error
        %%P setup.py build bdist_wheel upload || goto :error
    )
    echo OK
    goto :eof
)


if "%1" == "setup-env" (
    echo downloading pip installer
    C:\python27\python.exe -c "import urllib2; url = urllib2.urlopen('https://raw.github.com/pypa/pip/master/contrib/get-pip.py'); data = url.read(); f = open('get-pip.py', 'w'); f.write(data)"
    C:\python26\python.exe get-pip.py & C:\python26\scripts\pip install unittest2 wheel ipaddress --upgrade
    C:\python27\python.exe get-pip.py & C:\python27\scripts\pip install wheel ipaddress --upgrade
    C:\python33\python.exe get-pip.py & C:\python33\scripts\pip install wheel ipaddress --upgrade
    C:\python34\scripts\easy_install.exe wheel
    rem 64-bit versions
    C:\python27-64\python.exe get-pip.py & C:\python27-64\scripts\pip install wheel ipaddress --upgrade
    C:\python33-64\python.exe get-pip.py & C:\python33-64\scripts\pip install wheel ipaddress --upgrade
    C:\python34-64\scripts\easy_install.exe wheel
    rem install ipdb only for py 2.7 and 3.4
    C:\python27\scripts\pip install ipdb --upgrade
    C:\python34\scripts\easy_install.exe ipdb
    goto :eof
)

goto :help

:error
    echo ------------------------------------------------
    echo last command exited with error code %errorlevel%
    echo ------------------------------------------------
    exit /b %errorlevel%
    goto :eof
