# Pypilot controller for Apple Watch

As the Apple Watch cannot sustain direct TCP Stream communications with the
Pypilot we need an interface box to connect via BLE.

We may use the project od the PyPilot controller with a ESP32 (M5Dial)

The application native for Apple Watch has 2 screens depending mode :

- When the pylot is disengaged the app shows the rudder control screen
- When it is engaged shows the navigation screen

### Rudder Screen

- Shows the rudder position and heading in numbers in the center.
- At first line we have 2 arrow buttons for moving the rudder and a number. Clicking it may be changed with the crown.
when clicked again will put the rudder at the angle specified. The arros ars incremental, the number absolute.
- A click at the center will move the rudder to 0 angle
- At the bottom shows the mode. May be clicked and changed with the crown.
- Bottom right a red dot means disconnected, a green one means connected. Clicking the red one tries to reconnect.

### Navigation Screen

- First line is similar with a field in the center to set the desired rhumb by clicking an moving the crown.
- Arrows are for activating tacking. Long press one and changes to orange. Press again and starts tacking and turns green.
- Click again and cancels tacking.
- The center shows a compass and the rhumb numeric
- At bottom shows the mode that may be changed as before. Selecting ruddes disengages the autopilot.
- If pypilot does not support a mode will change back to compass.
- Bottom right the same dot for connection.

This apllication works with the M5Dial or other controllers for pypilot.

For example, canging in the Autopilot Control a value will be reflected in the M5Dial and the Watch.

Have fun!!!
