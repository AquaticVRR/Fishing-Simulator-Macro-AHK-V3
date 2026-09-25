https://drive.google.com/drive/folders/1wzQRA_VUS-hhFVlGrJAOCdPnNTui5kmo?usp=drive_link

this link is for downloading tesseract directly, if you know how to use command prompt or powershell you can go directly to tesseracts github, and tesseract is required for this. Tesseract must be in the same folder as the other 2 files

first step before even downloading. make sure you have autohotkey installed. this uses autohotkey v1

Next make a folder for both the config and Fishing Sim.ahk
make sure that both config and the ahk are in the same folder

how it works was not explained so here is the explanation

1: zone 1 is where the color for the bubble will be scanned
2: zone 2 make sure to set this to where the entire line is covered by green, preferably in the middle of the curved minigame.
3: zone 3 is just a color you want to scan for while the minigame is happening so when it disappears it knows the minigame is done and will restart the progress. this needs to be where the color chosen can detect it only during the minigame
4: configure your desired timings.

config settings:
click cooldown: this is how often the macro can click when it detects the vertical white line in the minigame
scan speed: how often the macro scans for everything
restart delay: after the restart color is no longer detected this is how long until it restarts the process
key toggle: set a key to turn the macro on and off.

My config is for computers that are on 1920 by 1080, it is customizable. the bubble color is set, click color is set, and restart color will need to be changed based on where you plan to place the restart box.

V2: features
1: autosell
Autosell requires you to be either near a seller or have the sell anywhere gamepass

Enable AutoSell OCR Check - pretty self explanetory

Set Tesseract OCR - you place this area over your backpack where the numbers are

specific match - you type in the requirements based on what you want to sell at (Left) and backspace (Right)
Auto Max - this just detects when your backpack is full

Test OCR - to make sure that where you have placed the set tesseract OCR has been placed works.

key to press - this is so if you have sell anywhere you press f, if you don't have it you stand near a merchant and make sure that the sell option is visible, other is in case of an update

Each of the positions are step 1, step 2, and step 3 in order seen. step 1 is for the sure option when asking if you have anything good. step 2 and for selling sell or sell everything button, step 3 is for the confirmation of the sell.

Dropdown - this lets you set the timings for each step depending on what is required for you

glide time - the amount of time it takes to get to the set location

hover time, the amount of time before it clicks (May be changed later to before the glide happens)

2: Failsafe Tab
just incase you want the click to happen sooner or later when no click is detected for a period of time
