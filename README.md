# Picture Frame
Picture Frame is a digital picture frame app written in Godot and compatible with Linux and Android.
It finds pictures in a folder and cycles through them.

## Usage
Click on the picture to open the settings menu and select a folder containing your pictures.
Close the menu by clicking outside of the menu on the picture.

### Panoramas/VR360 and VR180 pictures
Picture Frame supports 360° panoramas and 180° stereoscopic side-by-side photos by using them as a sky texture and pointing a 3D camera at them.

Picture Frame decides whether a picture is a panorama or a VR180 picture by checking whether its filename or any folder in the hierarchy starts with `panorama`, `vr360` or `vr180`.

With Picture Frame's base directory written as `BASE`, the following picture paths would be detected as a panorama or VR180 image:

* `BASE/panorama.jpg`
* `BASE/panorama/1.jpg`
* `BASE/smartphone/panorama/2.jpg`
* `BASE/my_360_camera/vr180_1.jpg`
