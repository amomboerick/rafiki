@echo off
call conda activate rafiki
set PATH=%PATH%;%USERPROFILE%\develop\flutter\bin
cd /d %USERPROFILE%\rafiki
echo Rafiki dev environment ready.
flutter --version