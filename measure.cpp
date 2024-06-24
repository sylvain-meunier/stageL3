#include "measure.hpp"
#include <vector>
#include <iostream>
#include <algorithm>

double distance(double a, double b, double x) {
    if (a > b) {
        return distance(b, a, x);
    }
    //return fabs(a-b);
    return fmin(fabs(a - b), fabs(a+x - b));
}

double get_measure(std::vector<double> spectre, double delta, double x, int i) {
    std::sort(spectre.begin(), spectre.end());
    Circle<double> c = Circle<double>(spectre, x, i);
    couple ind_end = c.get_start();
    couple ind_start = ind_end;
    int d = c.get(ind_end) - delta;
    for (int i = 0; i < c.size() - 1; i++) {
        ind_start = c.get_previous(ind_start);
        if (distance(c.get(ind_start), d, x) > delta) {
            ind_start = c.get_next(ind_start);
            break;
        }
    }
    double p = (double)c.get_cardinal(ind_start, ind_end) / (double)c.length();
    double S = p;

    while (true) {
        int d1 = c.get(ind_start) + delta; // Next start index change
        int d2 = c.get(c.get_next(ind_end)) - delta; // Next end index change
        int next_d = fmin(d1, d2);

        if (d1 <= d2) {
            p -= (double)c.get_count(ind_start) / (double)c.length();
        }
        if (d2 <= d1) {
            p += (double)c.get_count(ind_end) / (double)c.length();
        }
        S = fmax(S, p);
        d = next_d;

        if (d1 <= d2) {
            ind_start = c.get_next(ind_start);
            if (couple_eq(ind_start, ind_end)) {
                ind_end = ind_start;
            }
        }

        if (d2 <= d1) {
            ind_end = c.get_next(ind_end);
        }

        if (c.is_start(ind_end)) {
            return S;
        }
    }
}

int main() {
    std::vector<double> spectre = {1., 1., 1., 1., 1., 1., 1.2};
    std::cout << get_measure(spectre, 0.15, 1, 0);
    return 0;
}