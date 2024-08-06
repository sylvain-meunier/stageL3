= L3 Internship

This repository contains results, examples and algorithm implementations of the work presented in `report.pdf`

= Dependencies

The code presented here uses the following Python package:
- [`mido`](https://mido.readthedocs.io/en/stable/)
- [`symusic`](https://github.com/Yikai-Liao/symusic)
- [`partitura`](https://github.com/CPJKU/partitura)

= Organization

This repository is organized as follow :

`report.pdf` describes most of the theoretical background and presents broadly the works done here\
`util.py` contains useful functions and constants, in particular the path to the database to consider\
`models.py` contains all the models presented in the report\
`tempo_crusher.py` contains utilities for generating "midi-like" performance as explained in Section IV.A\
`example_plot.py` is a template useful for plotting different models on performances\
`generate_spectrogram.py` presents the code used to generate spectrogramms as images\
`compute_estimator_result.py` presents the code used to generate figures displaying the performances of the Estimators\
`generate_values.py` allows for saving in a pickle file the spectra obtained for a given Estimator model
`kappa.py` contains two constants used by the _Large et al._ model\
`perfgen.py` contains utilities and example codes for generating rough performances\
`pic.py` contains utilities for reading and writing files\
`plot.py` contains some code used for generating figures, along with utilities\
`quantization.py` contains a Python implementation of Algorithm 1 : FindLocalMinima

= Folders
- `Asap` : extracts from the [(n)-ASAP dataset](https://github.com/CPJKU/asap-dataset).
- `Results` : direct results of our works
    - `Figures` : obtained figures (notably those of the report in better resolution)
    - `Performance` : results of different estimators, tested over the whole (n)-ASAP dataset. The value indicated at the end of the name is the value of Δ used for the measure computation
- `Examples` : examples of applications
    - `PerfGen` : generated monophonic pieces or samples
- `Measure` : C++ code for the computation of the measure `m` defined in the report. In order to use said code, follow the instructions given [here](#Measure).

= Measure

In order to use the `measure` function defined in ..., one should compile the Python library using the two following commands (here showed for MacOS) from the `Measure` folder using Pybind.

static library :\
```clang++ -O3 -shared -std=c++17 -fPIC measure.cpp -o libmeasure.so -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib```

python librairy :\
```clang++ -O3 -shared -std=c++17 -undefined dynamic_lookup -fPIC `/usr/local/bin/python3 -m pybind11 --includes` -I /usr/include/python3.10 -I .  pybind11_wrapper.cpp -o py_measure`/usr/local/bin/python3.10-config --extension-suffix` -L. -lmeasure -Wl,-rpath,.```

Then, move the obtained python file (called by default `cpp_measure`) in the same folder as `util.py`, and uncomment the final lines of the latter.