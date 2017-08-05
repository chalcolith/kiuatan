@echo off
set TARGET=kiuatan

where stable > nul
if errorlevel 1 goto nostable
where ponyc > nul
if errorlevel 1 goto noponyc

if "%1"=="clean" goto clean

if not exist bin mkdir bin

set DEBUG=
if "%1"=="--debug" set DEBUG="--debug"
if "%1"=="test" goto test

:build
stable fetch
stable env ponyc %DEBUG% -o bin %TARGET%
if errorlevel 1 goto error
goto done

:test
if "%2"=="--debug" set DEBUG="--debug"
if not exist bin\%TARGET%.exe (
  stable fetch
  stable env ponyc %DEBUG% -o bin %TARGET%
)
if errorlevel 1 goto error
bin\%TARGET%.exe --sequential
if errorlevel 1 goto error
goto done

:clean
rmdir /s /q bin
goto done

:nostable
echo You need "stable.exe" (from https://github.com/ponylang/pony-stable) in your PATH.
goto error

:noponyc
echo You need "ponyc.exe" (from https://github.com/ponylang/ponyc) in your PATH.
goto error

:error
%COMSPEC% /c exit 1

:done
