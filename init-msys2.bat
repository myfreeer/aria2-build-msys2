@echo off
pushd "%~dp0"
setlocal EnableExtensions EnableDelayedExpansion

:Deps
set MSYSTEM=MINGW64
REM MINGW64 means 64-bit build; MINGW32 means 32-bit build;

set msysbin=msys64\usr\bin
set sh=%msysbin%\bash
set pacman=%msysbin%\pacman
if exist msys64\mingw64.exe goto :Update
if exist busybox.exe if exist msys2-x86_64-latest.tar.xz goto :Extract
echo. dependency broken. download msys2-x86_64-latest.tar.xz and busybox.exe and put them in the same folder of the script.
echo. download busybox.exe from https://frippery.org/files/busybox/busybox.exe
echo. and deonload msys2-x86_64-latest.tar.xz from http://repo.msys2.org/distrib/msys2-x86_64-latest.tar.xz
pause
exit /B -1

:Extract
busybox tar -Jxvf msys2-x86_64-latest.tar.xz

:Init
%sh%  -lc "pacman-key --init && exit" 2>&1 | busybox tee -a init.log

:Chi_Mirror
for %%i in ( mirrorlist.mingw32 mirrorlist.mingw64 mirrorlist.msys) do if exist %%i copy /y %%i msys64\etc\pacman.d\

:Update
%pacman% -Syyuu --needed --noconfirm 2>&1 | busybox tee -a update.log
%pacman% -Suu --needed --noconfirm 2>&1 | busybox tee -a update.log

:Install
%pacman% -S --needed --noconfirm base-devel zlib-devel sqlite git unzip zip tar gmp gmp-devel libssh2 libssh2-devel openssl-devel 2>&1 | busybox tee -a install.log
%pacman% -Sc --noconfirm 2>&1 | busybox tee -a install.log

:Clone
%sh%  -lc "if [[ -d ~/aria2 ]]; then cd aria2; git pull; else git clone https://gist.github.com/a780c730b7282e090f238e8286f815f3.git aria2; cd aria2; git pull; fi" 2>&1 | busybox tee -a clone.log

:Build
%sh%  -lc "cd ~/aria2 && exec ./build-aria2.sh" 2>&1 | busybox tee -a build.log
pause