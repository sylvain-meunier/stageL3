#include "measure.hpp"
#include <vector>
#include <iostream>
#include <algorithm>

void print_couple(couple a) {
    auto [i, k] = a;
    std::cout << "(" << i << ", " << k << ')';
}

double distance(double a, double b, double x) {
    if (a > b) {
        return distance(b, a, x);
    }
    //return fabs(a-b);
    return fmin(fabs(a - b), fabs(a+x - b));
}

double get_measure(std::vector<double> spectre, const double delta, const double x, int i) {
    std::sort(spectre.begin(), spectre.end());
    Circle<double> c = Circle<double>(spectre, x, i);
    couple ind_end = c.get_start();
    couple ind_start = ind_end;
    double d = c.get(ind_end) - delta;
    for (int i = 0; i < c.size() - 1; i++) {
        ind_start = c.get_previous(ind_start);
        if (distance(c.get(ind_start), d, x) > delta) {
            ind_start = c.get_next(ind_start);
            break;
        }
    }
    int p = c.get_cardinal(ind_start, ind_end);
    int S = p;

    int h = 0;
    while (h+1 < c.size()) {
        double d1 = delta - distance(c.get(ind_start), d, x); // Next start index change
        if (c.get(ind_start) > d) {
            d1 = -d1 + 2*delta;
        }
        double d2 = distance(c.get(c.get_next(ind_end)), d, x) - delta; // Next end index change

        if (d1 <= d2) {
            p -= c.get_count(ind_start);
        }
        if (d2 <= d1) {
            h++; // A new point enters the delta area
            p += c.get_count(ind_end);
            S = fmax(S, p);
        }
        d += fmin(d1, d2);

        if (d1 <= d2) {
            ind_start = c.get_next(ind_start);
            if (couple_eq(ind_start, ind_end)) {
                ind_end = ind_start;
            }
        }

        if (d2 <= d1) {
            ind_end = c.get_next(ind_end);
        }
    }
    return (double)S / (double)(c.length());
}

int main() {
    std::vector<double> spectre = {1., 1., 1., 1., 1., 1., 1.2};
    std::cout << get_measure(spectre, 0.15, 1, 0);
    return 0;
}