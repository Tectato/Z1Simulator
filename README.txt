# Z1Simulator

A universal simulation environment for mechanical binary computers built using the Z1's principles.

## Interaction & Basics

Hold Middle Mouse or Alt to orbit the camera, additionally hold Shift to pan the camera. Scroll to zoom.
Interaction with levers, pull tabs, red buttons, or pins with checkboxes above, happens via right click.


(The text below is from an older README and in parts refers to projects not included in this repository)

## Project structure

References to sheet files and instanced projects are all relative paths, meaning that you can move (and share with others) your machine folders arbitrarily as long as they keep the same structure relative to each other. If you want to move a project relative to the files it references you can just load it where it currently is and save it again in the new location.

## Adding circuit diagrams

With a layer selected, drag and drop an image of your diagram into the program. This will then set it as the "plan" for that layer in the appropriate tab of the side window.

### Adding markings
In this interface, you have a separate Selector and Editor tool. If no marking is selected with the Selector, switching to the Editor will create a new one. Now you can add shapes to the marker from the selection buttons above.
- Circle: click in the middle of where it should go and drag to set its radius.
- Rectangle: click on the first corner and drag to the second corner.
- Line: left click to add points, double click or right click to finish the line.
- State label: click to place. While selected, press R to cycle directionality and F to flip its current value.
These shapes can be selected and moved with the Editor tool, and markings as a whole can be duplicated with Ctrl + D and moved with the Selector tool. Hold shift to select multiple markings at once.

### Part colourcoding
Once you've added one or more markings, select one of them and a part in the 3D scene, then click the "link" button in the top left of the plan interface to connect the two. The 3D part will take on the same colour and any state labels in the marker will update as the part moves.
Right-click with one or more markings selected to change their colour.


## Blender scripts

### ImportZ1Project
Create a new collection and select it in the scene tree. Run the script and select the project file in the popup. Depending on the scale and number of unique parts it may take a while to run.
Once imported, there are four materials (static/fixed pins, static/fixed sheets) which are shared by the respective parts, so you can easily edit these without bothering to copy the changes for every single part. I would recommend adding a bevel node to each shader.
To approximate the dimensions of the real machines better (both in terms of the thickness of sheets and the total height), you can scale the empty root object of every machine by 0.5 on the Z-axis.

### ImportZ1Recording
In the simulator, click Edit->Start Recording. Step forward in the simulation a bit (up to 15 cycles), then click Edit->Stop Recording. A new file will be created next to the project file, of the same name but with "_recording" at the end.
In Blender, provided that you have previously imported the project with the above script, run this second script and select the recording file in the popup. This will create animation keyframes for every part that moved in the recording. The c_frameSpacing constant at the top of the script determines the spacing of these keyframes. 8 keyframes make up one clock cycle, so for a 1Hz clock at 24fps you would set this value to 3, for instance.
If you simulate the scene at the same clock frequency in the first place you can record the audio to then match the render.


# Z1SVGEditor

## Working from a reference

To digitise a sheet from a blueprint or drawing, start by importing the image either through File->Import Image or by drag & drop into the program. Selecting the image will make two crosshairs appear. You can right-click and drag to position these freely in the image, then left-click and drag them to scale and rotate the image. Zuse's own drawings were (for the most part) done on paper with a 15mm grid, which you can see in the program as well. We recommend positioning the crosshairs on those markings in the image and moving them to align with their equivalents in the background.
If you're digitising multiple sheets from one image, you can clear the previous work by selecting the reference image, pressing Ctrl + I to invert the selection, and pressing X to delete.

## Drawing sheets

A valid sheet consists of exactly one outline and any number of holes. Each tool provides a tooltip with relevant key inputs below. After you're done placing your parts, just click File->Save as... to export the sheet file. Sheets can be loaded or drag & dropped to edit them.