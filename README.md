
Moon textures generator for FlightGear's Earthview
===

This code allows you to create Moon textures, RGB [**normal
map**](https://en.wikipedia.org/wiki/Normal_mapping) and
[**heightmaps**](https://en.wikipedia.org/wiki/Heightmap) from the
fantastic public domain LROC images. LRO(C) stands for the Lunar
Reconnaissance Orbiter (Camera) satellite from NASA/GSFC/Arizona State
University.

Checkout the
[**wikipedia**](https://en.wikipedia.org/wiki/Lunar_Reconnaissance_Orbiter)
webpage or the [**LROC**](http://lroc.sese.asu.edu/) page for more
details and direct access to the data.


Running
---

You need a working installation of imagemagick (API6>=), the
**normalmap** binary that can be obtained at
(https://github.com/eatdust/normalmap) and a working installation of
[**GDAL**](https://gdal.org/).

Then launch the bash script:

    $ ./moontextures moon heights 8k

The script is adapted from the one by Chris Blues which generate Earth
textures, more info can be found at
[**NASA2FGearthview**](https://github.com/chris-blues/Nasa2FGearthview)

As an illustrative example, here the FlightGear's UFO above [**Mare
Orientale**](https://en.wikipedia.org/wiki/Mare_Orientale). The GLSL
shaders are provided in the
[**moonshaders**](https://github.com/eatdust/moonshaders) repository.

![orientale](/docs/orientale.png?raw=true)



Credits
---

* Chris_Blues (https://github.com/chris-blues/Nasa2FGearthview)

* LROC images, NASA/GSFC/Arizona State (http://lroc.sese.asu.edu/about/terms)

Videos
---

* Check out the FlightGear's forum (https://forum.flightgear.org/viewtopic.php?f=19&t=37534)

License
---

[**GPLv2**](http://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
