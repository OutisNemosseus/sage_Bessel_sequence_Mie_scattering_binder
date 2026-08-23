# Sage ComplexBall spherical sequences → Go Mie rendering

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/OutisNemosseus/sage-go-mie-binder/HEAD?urlpath=lab/tree/01_Sage_Spherical_Sequence_API_Export.ipynb)

This Binder-ready repository demonstrates the proposed certified spherical
Bessel/Hankel sequence API and then uses Go for the repeated radial, angular,
and pixel calculations of a Mie-scattering image.

## Run order

1. Open `01_Sage_Spherical_Sequence_API_Export.ipynb` with the **SageMath**
   kernel and run all cells.  It writes
   `sage-spherical-sequences-for-go.json`.
2. Open `02_Go_Spherical_Sequence_Render.ipynb` with **Go (gonb)** and run all
   cells.  It validates all 344 complex values and displays the eight sequence
   magnitudes.
3. Open `03_Go_Mie_Scattering_From_Sage_JSON.ipynb` with **Go (gonb)** and run
   all cells.  It computes the Mie coefficients, radial cache, Legendre
   sequences, and multipole sums, then displays the total and scattered fields.

The fixed `full_800` profile is used throughout:

- grid: 800 × 800;
- maximum order: 42;
- wavelength: 0.2;
- sphere radius: 3.18 wavelengths;
- refractive index: 1.33 + 0 i;
- relative permeability: 1.

## PR provenance

The proposal is Sage commit
`dda09a7229a39589ef50dedcabd1c40de9d4f856` on branch
`OutisNemosseus:spherical-bessel-sequences`.

The stable Sage 10.9 Binder image predates the unmerged API.  During the Binder
image build, the Dockerfile applies the complete two-file PR patch directly to
`/home/sage/sage/src/sage/functions/all.py` and
`/home/sage/sage/src/sage/functions/bessel.py`.  It then imports all three
functions from `sage.all` and verifies their source path.  The build fails if
the patch or source verification fails; there is no fallback implementation.

This avoids rebuilding all of SageMath while genuinely running the modified
Sage source with `ComplexBallField(192)`, the public API signatures, domain
restrictions, parent preservation, and certified Arb enclosures.

## Generated files

- `sage-spherical-sequences-for-go.json`
- `sage-spherical-sequences-go-render.png`
- `sage-api-go-mie-total.data`
- `sage-api-go-mie-scattered.data`
- `sage-api-go-mie-total.png`
- `sage-api-go-mie-scattered.png`

The two `.data` files contain row-major little-endian `float64` values.  Images
are also displayed directly inside the Go notebooks.

## Publishing

Create an empty GitHub repository named `sage-go-mie-binder`, upload all files
from this directory to its default branch, and open the Binder badge above.  If
you use a different repository name, change the badge target in this README.
