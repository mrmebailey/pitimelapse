# pitimelapse
Shell Script for automating time-lapse video creation from images, hosts on an Apache Web Server for easy viewing.

Here's an example time-lapse video I recorded of chilli peppers growing over an 7 month period (click to view on YouTube):

<p align="center"><a href="https://www.youtube.com/embed/c2NePLQ2OQk"><img src="http://img.youtube.com/vi/VIDEO-ID/0.jpg" alt="Chilli Time-lapse by Mark Bailey" /></a></p>

[![SC2 Video](https://img.youtube.com/vi/c2NePLQ2OQk/0.jpg)](https://www.youtube.com/embed/c2NePLQ2OQk)


There are many other examples in my <a href="https://www.youtube.com/channel/UCq2082CCgrotqy21P-IxtTw">Timelapses</a> playlist on YouTube.

First, make sure the camera interface is enabled—if you don't, you'll see the message `Camera is not enabled. Try running 'sudo raspi-config'`:

  1. Run `sudo raspi-config`
  2. Go to 'Interfacing Options'
  3. Select 'Camera'
  4. Select 'Yes' for enabling the camera
  5. Select 'Finish' in the main menu and then 'Yes' to reboot the Pi

<iframe width="560" height="315" src="https://www.youtube.com/embed/c2NePLQ2OQk" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Usage


