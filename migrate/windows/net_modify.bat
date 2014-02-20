@echo off

netsh interface ip show address > C:\Users\Administrator\interface.txt


FOR /F tokens^=2^ delims^=^" %%G IN (C:\Users\Administrator\interface.txt) DO (

echo %%G
netsh interface ip set address name="%%G" source=dhcp

netsh interface ip set dns name="%%G" source=dhcp register=PRIMARY
netsh interface ip set wins name="%%G" source=dhcp
)

: is annotation

del "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\net_modify.bat"

:timeout /t 30
