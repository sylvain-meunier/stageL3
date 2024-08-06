#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include "measure.hpp"

PYBIND11_MODULE(py_measure, m) {
    m.def("cpp_measure", &get_measure, "Computes the measure of given a spectrum");
}