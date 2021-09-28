[This document is formatted with GitHub-Flavored Markdown.    ]:#
[For better viewing, including hyperlinks, read it online at  ]:#
[https://github.com/mrmebailey/pitimelapse/blob/main/README.md]:#

* [Overview](#Overview)
* [Prerequisites](#prerequisites)
* [Enable Camera](#enable-camera-module)
* [Install Apache 2](#install-apache)
* [Install Video software](#ffmpeg)
* [Install piLapse](#install-pilapse)

* [Installation](#installation)

# Overview
Shell Script for automating time-lapse video creation from images, hosts on an Apache Web Server for easy viewing.

Here's an example time-lapse video I recorded of chilli peppers growing over an 7 month period (click to view on YouTube):

[![SC2 Video](https://img.youtube.com/vi/c2NePLQ2OQk/0.jpg)](https://www.youtube.com/embed/c2NePLQ2OQk)

Another over a much shorter period in HD which was taken every 10 minutes.
[![SC2 Video](https://img.youtube.com/vi/qcc47tjRBUc/0.jpg)](https://www.youtube.com/embed/qcc47tjRBUc)

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

#Iinstall piLapse

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

# testing
Now we have the script we can start testing, you will need the IP of your Pi to visit the 
web URL.





