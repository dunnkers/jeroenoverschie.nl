> ## Content Index
> Fetch the complete content index at: https://jeroenoverschie.nl/llms.txt
> Use this file to discover other available public pages before exploring further.

# Automated curtains project
- URL: https://jeroenoverschie.nl/automated-curtains/
- Published: 2020-02-09T23:00:00.000Z
- Updated: 2024-11-22T13:36:41.000Z
- Description: My electric curtains can already be controlled by a remote. It would be cool if they could open in the morning, like an alarm clock. What if I could do this using a Raspberry Pi, by emulating the remote?
- Author: Jeroen Overschie
- Tags: Internet of Things

An idea sprung up in my mind some while ago. In my student dorm, I have electric curtains. They can be operated using a little remote, allowing one to open or close the curtains. This is pretty useful, because I don't even have to get out of bed to open my curtains – I can just use the remote. But the remote uses radio waves to operate the curtains - and I have a Raspberry Pi laying around, doing nothing. What if I could operate the curtains using my Raspberry Pi? Such, that the curtains open at a certain time in the morning. In this way, my curtains would function as an alarm clock! In this project, I did exactly that 😉.

### How

First, I have to figure out at all how to do this. Taking a look at the curtain remote, I found the brand to be '*Somfy'*. After some Google image searches I found the name of my remote model, the Somfy Telis 1-RTS:

![](https://jeroenoverschie.nl/content/images/2021/11/SOMFY-TELIS-1-RTS-old.jpeg)

My curtain remote. The goal is to emulate whatever signal it is sending to the curtains using a Raspberry Pi.

I want to emulate the RF (Radio Frequency) signal the remote is emitting. Such that, instead of pressing a button on the remote, I can control the curtains programmatically using code. Then, because the Raspberry Pi will always be on, I can configure certain times to open/close the curtains.

But surely, other people have wanted to do this too. Somfy is a popular brand for electric curtains after all. So, I searched, and found [Github project](https://github.com/Nickduino/Pi-Somfy) containing code to control the curtains using a Raspberry Pi, if correctly assembled. Let's start!

### Preparation

I need a couple things to make this work.

1. Raspberry Pi (I am using a Raspberry Pi 2011 edition - Model B)
2. RF (Radio Frequency) transmitter (with an oscillator at 433.42 Mhz)
3. Cables to connect the RF emitter to the Raspberry Pi

Most parts could easily be ordered through Ebay. However, Somfy did something smart in their product. They intentionally set their oscillator frequency to an odd number, 433.42 Mhz. Most other RF emitters run at 433.93 Mhz. There are, luckily, some places you can order a 433.42 oscillator. But only the oscillator. This means we are going to have to do some soldering to replace the oscillator. After a couple weeks, my parts arrived.

![](https://jeroenoverschie.nl/content/images/2021/11/Photo-from-Jeroen-Overschie-3.png)

The RF emitter on the left and a replacement part for changing its oscillator frequency on the right.

### Building the Pi emitter

My friend happened to possess a soldering set, so after a quick visit I managed to solder the correct oscillator onto the RF emitter board. Using a set of cables, I could attach the RF transmitter to the Raspberry Pi 🙌🏻.

![](https://jeroenoverschie.nl/content/images/2021/11/Screen-Shot-2021-11-26-at-14.49.31.png)

The fully assembled Raspberry Pi, with its RF emitter attached via a cable.

I also bought an extra enclosure to keep the thing a bit more safe:

![](https://jeroenoverschie.nl/content/images/2021/11/image00003.jpeg)

Assembled Raspberry Pi RF transmitter, with enclosure.

Now all there's left is configure the correct software on the Raspberry Pi. Using the Github project I found, I was able to install the software and make the software automatically start on a reboot. It has a pretty neat interface, allowing one to set CRON jobs to open/close the curtains. In non-nerd speech we would just call this 'an alarm' 😅.

![](https://jeroenoverschie.nl/content/images/2021/11/p3.png)

The Pi-Somfy interface. One can easily connect to a web server running on the Pi if on the same network, allowing me to configure the alarms even on my phone.

I now just had to execute a certain pattern of button presses to emulate pairing a new remote. And then ... it worked! 🎉

![](https://jeroenoverschie.nl/content/images/2021/11/ezgif-2-a5aab328d979.gif)

Opening my curtains using the Raspberry Pi and its RF sensor.

Now, I can go to sleep in darkness, and wake up with sunlight hitting my face 🌞. Awesome! The project has succeeded and the cool thing is I have been using this every day ever since. The cool thing about doing a Computer Science degree is when you can apply your knowledge to solve real-world problems. When I leave this student dormitory, I will leave the Raspberry Pi right where it is, so others can also benefit from automated curtains 😊. Cheers!