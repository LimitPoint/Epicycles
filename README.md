![Epicycles](https://www.limit-point.com/assets/images/Epicycles.jpg)
# Epicycles
## Fourier coefficients of 2D curves are generated with numerical integration and displayed with epicycles. 

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

[SwiftUI]: https://developer.apple.com/tutorials/swiftui
[Euler's formula]: https://en.wikipedia.org/wiki/Euler%27s_formula
[epicycles]: https://en.wikipedia.org/wiki/Deferent_and_epicycle
