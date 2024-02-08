## Descrition

This is a simple IDL widget to get the coordinates of an arbitrary curve (spline) on a 2-D image.
It might turn useful for extracting the data from a 2-D image/array along some manually-defined curve.

It's current status is an MVP, further development is not scheduled for the foreseable future, but still possible.
Hence, any commits are wellcome.


## Usage

```
spline = draw_curve(img, /x, /y, /full)
```

**Inputs:**
*image* - a byte-scaled 2-D array to be dsplayed in the widget.

**Keywords:**
*/x* or */y* - use these keywords specify the primary axis for the spline. */x* is the default.

            */full* - set this keyword to continue the spline to the edges of the image.

**Outputs:**
*spline = {x, y}* - and IDL structure containing the *x* and *y* pixel coordinates of the spline.

- The above command opens a widget displaying the provided *image* in its main window.
Current display options (e.g. the color scheme) will be applied.
If the image is too large to be displayed on the screen, scroll bars will be added.
The image can be zoomed in and out with the [+] and [-] buttons at the bottom of the widget.
- Left click on the image to add an interpolation point, right click on the previously added point to remove it.
Position of the added points can be adgustet by dragging them with the left mouse button pressed.
When three or more ponts arre added, a spline is drawn through tese points.
Press the [Clear] button at the bottom of the widget to remove all point and start over.
- When finished, press the [OK] button to terminate the widget and return the spline coordinates.


## Example
```
x = rebin(findgen(100)/10-5,100,100)               ; constructing the example image from an arbitrary function
y = rebin(transpose(findgen(100)/10-5),100,100)
r = (x^2+y^2)^0.5
f = exp(-r^2/9)*cos(r*5)/20 + exp(-((x-2)^2+(y+1)^2)/4) - exp(-((x+1)^2/2+(y-2)^2)/4) 
i = bytscl(f, min=-1, max=1)

s = draw_curve(i, /x)                              ; getting the spline coordinates with the widget

d = interpolate(f, s.x, s.y, cubic=-0.5)           ; getting the function values along the spline
dx = s.x[1:*]-s.x
dy = s.y[1:*]-s.y
dl = (dx^2+dy^2)^0.5
l = [0,total(dl, /cum)]
plot, l, d, xtit='Distance aling the curve, pix', ytit='Interpolated intensity'
```
