![Epicycles](https://www.limit-point.com/assets/images/Epicycles.jpg)
# Epicycles
## Fourier coefficients of a 2D curve are generated with numerical integration and displayed as epicycles.  

The associated Xcode project implements an iOS and macOS [SwiftUI] app that numerically calculates the Fourier series of sampled parametric curves _(x(t), y(t))_ in the plane, points drawn by the user, or the samples of finite Fourier series created with a terms editor. 

Experiment with complex Fourier series of the form:

<img src="https://www.limit-point.com/assets/images/Epicycles-FourierSeriesForm.png" width="223">

By [Euler's formula] the _n-th_ term (or _frequency component_) of the Fourier series is a complex number that traces a circle with radius r<sub>n</sub> in the 2D plane _n_ times as _t_ traverses an interval (period) of length 2π. The values of the sum trace the path of the function _f(t)_ as _t_ traverses an interval (period) of length 2π:

<table>
<tr>
<td><img src="https://www.limit-point.com/assets/images/Epicycles-Animation.gif"></td>
<td><img src="https://www.limit-point.com/assets/images/Epicycles-Animation2.gif"></td>
<td><img src="https://www.limit-point.com/assets/images/Epicycles-Animation3.gif"></td>
</tr>
</table>

The circles in these animations that rotate on top of other circles are called [epicycles]. Each epicycle corresponds to a term of the complex Fourier series. The origin is at the constant term _n = 0_.

The partial sums of the Fourier series are used to draw the red line segment path in the animations, and also locate the centers of each blue epicycle circle. The radius of each epicycle circle is the magnitude of its corresponding Fourier series coefficient:

<img src="https://www.limitpointstore.com/products/epicycles/images/circle-lightning.png">

The origin of every red line segment path is determined by the constant term of the Fourier series, n = 0, and is fixed in time.
 
The end of every red line segment path is the value of the whole Fourier series, and is located at the green circle in the animations:

<img src="https://www.limitpointstore.com/products/epicycles/images/circle-eye-lightning-zoomed.png">

The green circle follows the approximating curve of the Fourier series, drawn in black over the orange curve of the function f(t):

<img src="https://www.limitpointstore.com/products/epicycles/images/circle-eye-lightning-pencil-star.png">

[SwiftUI]: https://developer.apple.com/tutorials/swiftui
[Euler's formula]: https://en.wikipedia.org/wiki/Euler%27s_formula
[epicycles]: https://en.wikipedia.org/wiki/Deferent_and_epicycle
