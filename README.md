[This document is formatted with GitHub-Flavored Markdown.    ]:#
[For better viewing, including hyperlinks, read it online at  ]:#
[https://github.com/mrmebailey/pitimelapse/blob/main/README.md]:#

* [Overview](#Overview)
* [Prerequisites](#prerequisites)
* [Enable Camera](#enable-camera-module)
* [Install Apache 2](#install-apache)
* [Install Video software](#ffmpeg)
* [Install piLapse](#install-pilapse)
* [VNC Install](#vnc-install-pi-hd-lens-only)
* [Camera Focus](#camera-focus-pi-hd-lens-only)
* [Testing](#testing)

# Overview
Shell Script for automating time-lapse video creation from images, hosts on an Apache Web Server for easy viewing.

Another over a much shorter period in HD which was taken every 10 minutes.
[![SC2 Video](https://img.youtube.com/vi/qcc47tjRBUc/0.jpg)](https://www.youtube.com/embed/qcc47tjRBUc)

Here's an example time-lapse video I recorded of chilli peppers growing over an 7 month period (click to view on YouTube):
[![SC2 Video](https://img.youtube.com/vi/c2NePLQ2OQk/0.jpg)](https://www.youtube.com/embed/c2NePLQ2OQk)


There are other examples in my <a href="https://www.youtube.com/channel/UCq2082CCgrotqy21P-IxtTw">Timelapses</a> playlist on YouTube.


# Prerequisites
## Enable Camera Module
First, make sure the camera interface is enabled, if you don't, you'll see the message `Camera is not enabled. Try running 'sudo raspi-config'`:

  1. Run `sudo raspi-config`
  2. Go to 'Interfacing Options'
  3. Select 'Camera'
  4. Select 'Yes' for enabling the camera
  5. Select 'Finish' in the main menu and then 'Yes' to reboot the Pi

## Install Apache

Update the package lists first ;

```bash
sudo apt update
sudo apt-get install apache2 -y
```
Adjust the Apache permissions to allow the pi user to write so the script does not need to run
as root.

```bash
sudo usermod -a -G www-data pi
sudo chown -R -f www-data:www-data /var/www/html
```

## ffmpeg

Install ffmpeg

```bash
sudo apt install -y ffmpeg
```

Check it installed by checking the version

```bash
ffmpeg -version
```

# Install piLapse

Install Pi-Lapse as Pi

```bash
cd ${HOME}
curl -LJO https://raw.githubusercontent.com/mrmebailey/pitimelapse/main/timeLapse.sh
```

Check it downloaded fine ;

```bash
./timeLapse.sh
```
You should see the output 

```bash
This script will create a folder in the HTML Root with the project name

Usage: $0 [Project Name in HTML Root to be created, no spaces...]
```

# VNC Install Pi HD lens Only
Becuase the Pi runs headless we need to use VNC to logon to the Pi in order to focus the camera as no display is attached.
```bash
sudo apt update
sudo apt install realvnc-vnc-server realvnc-vnc-viewer
```
Now we need to enable VNC in raspi-config
```bash
sudo raspi-config
```
Navigate to Interfacing Options.

Scroll down and select VNC › Yes.

# Camera Focus Pi HD lens Only
Connect to the pi by donwloading VNC Viewer and execute raspistill in live mode using the 
command below.

```bash
raspistill -t -0
```

![Alt Image text](/resources/vnc_camera_command.png?raw=true "Camera Command")

Focus the camera on your subject in live view, do not forget to lock off the lens screws

![Alt Image text](/resources/vnc_focus.png?raw=true "Camera Command")


# Your First Time-Lapse - Lets go.....
Now we have the script we can start testing, you will need the IP of your Pi to visit the 
web URL.
