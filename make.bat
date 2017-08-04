@echo off
if "%1"=="clean" goto clean

if not exist bin mkdir bin

set DEBUG=
if "%1"=="--debug" set DEBUG="--debug"
if "%1"=="test" goto test

:build
stable env ponyc %DEBUG% -o bin kiuatan
if %ERRORLEVEL% gtr 0 goto error
goto done

:test
if "%2"=="--debug" set DEBUG="--debug"
if not exist bin\kiuatan.exe stable env ponyc %DEBUG% -o bin kiuatan
bin\kiuatan.exe --sequential
if %ERRORLEVEL% gtr 0 goto error
goto done

:clean
rmdir /s /q bin
goto done

:error
exit %ERRORLEVEL%

:done
