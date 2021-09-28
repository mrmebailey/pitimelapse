[This document is formatted with GitHub-Flavored Markdown.    ]:#
[For better viewing, including hyperlinks, read it online at  ]:#
[https://github.com/mrmebailey/pitimelapse/blob/main/README.md]:#

* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Enable Camera](#enablecamera)
* [Install Apache 2](#apache2)
* [Install Video software](#ffmpeg)
* [Clone timelapse](#clonelapse)
* [Installation](#installation)

# overview
Shell Script for automating time-lapse video creation from images, hosts on an Apache Web Server for easy viewing.

Here's an example time-lapse video I recorded of chilli peppers growing over an 7 month period (click to view on YouTube):

[![SC2 Video](https://img.youtube.com/vi/c2NePLQ2OQk/0.jpg)](https://www.youtube.com/embed/c2NePLQ2OQk)

There are other examples in my <a href="https://www.youtube.com/channel/UCq2082CCgrotqy21P-IxtTw">Timelapses</a> playlist on YouTube.


# prerequisites
## enablecamera
First, make sure the camera interface is enabled, if you don't, you'll see the message `Camera is not enabled. Try running 'sudo raspi-config'`:

  1. Run `sudo raspi-config`
  2. Go to 'Interfacing Options'
  3. Select 'Camera'
  4. Select 'Yes' for enabling the camera
  5. Select 'Finish' in the main menu and then 'Yes' to reboot the Pi

## apache2

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

# clonelapse

Install Pi-Lapse as Pi

```bash
cd ${HOME}
curl -LJO https://raw.githubusercontent.com/mrmebailey/pitimelapse/main/timeLapse.sh
```

Check it downloaded fine ;

```bash
cd ${HOME}
curl -LJO https://raw.githubusercontent.com/mrmebailey/pitimelapse/main/timeLapse.sh
```
You should see the output 

```bash
This script will create a folder in the HTML Root with the project name

Usage: $0 [Project Name in HTML Root to be created, no spaces...]
```






