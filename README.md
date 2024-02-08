## Descrition


This is a simple IDL widget to get coordinates of an arbitrary curve (spline) on a 2-D image.
It might be useful for extracting the data from a 2-D image/array along a user-defined curve.



## Usage

```
spline = draw_curve(img, /x, /y, /full)
```

**Inputs:**
*image* - a bit-scaled 2-D array to be dsplayed in the widget



## Example
```
x = rebin(findgen(100)/10-5,100,100)              ; constructing an example image from an arbitrary function
y = rebin(transpose(findgen(100)/10-5),100,100)
r = (x^2+y^2)^0.5
f = exp(-r^2/9)*cos(r*5)
img = bytscl(f, min=-1, max=1)

s = draw_curve(img, /x)                            ; getting the spline coordinates with the widget

g = interpolate(f, s.x, s.y, cubic=-0.5)           ; getting the function values along the spline
dx = s.x[1:*]-s.x
dy = s.y[1:*]-s.y
dl = (dx^2+dy^2)^0.5
l = [0,total(dl, /cum)]
plot, l, g, xtit='Distance aling the curve, pix', ytit='Interpolated intensity'
```
