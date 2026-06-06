@echo off
set ANDROID_HOME=C:\Users\wasik\AppData\Local\Android\sdk
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=C:\src\flutter\bin;C:\Program Files\Git\cmd;%PATH%
cd /d C:\src\cpva_app
flutter build apk --debug
