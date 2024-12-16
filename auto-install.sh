#!/bin/bash
apt update
apt upgrade -y
apt install -y python3-dev python3-venv
python3 -m venv /opt/gps-service/opt/gps-service/bin/pip install pygnssutils
cat >/etc/systemd/system/gnssserver.service <<'service'
[Unit]Description=GNSSServer
[Service]
Environment=PYTHONUNBUFFERED=1
User=root
Group=root
ExecStart=/opt/gps-service/bin/gnssserver -I /dev/ttyACM0 --baudrate=115200 --verbosity=2 --format=2 --protfilter=1
[Install]
WantedBy=multi-user.target
Alias=gnssserver.service

service

cat >/opt/wifi-restart.sh <<'wifirestartscript'
#!/bin/bash

SSID=$(/sbin/iwgetid --raw)

if [ -z "$SSID" ]; then
    echo "`date -Is` WiFi interface is down, trying to reconnect" >> /var/log/wifi-log.txt
    if command -v /sbin/ip &> /dev/null; then
        /sbin/ip link set wlan0 down
        sleep 10
        /sbin/ip link set wlan0 up
    elif command -v sudo ifconfig &> /dev/null; then
        sudo ifconfig wlan0 down
        sleep 10
        sudo ifconfig wlan0 up
    else
        echo "`date -Is` Failed to reconnect: neither /sbin/ip nor ifconfig commands are available" >> /home/pi/wifi-log.txt
    fi
fi

echo 'WiFi check finished'
wifirestartscript

chmod +x /opt/wifi-restart.sh
systemctl daemon-reload
systemctl enable gnssserver

echo '* *     * * *   root    /opt/wifi-restart.sh' >> /etc/crontab
