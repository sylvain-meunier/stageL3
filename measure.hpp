#include <vector>

using couple = std::pair<int, int>;

bool couple_eq(couple c1, couple c2) {
    auto [a, b] = c1;
    auto [c, d] = c2;
    return (a == c) && (b == d);
}

template <typename T>
class Circle {
    std::vector<T> t;
    std::vector<int> count;
    double x;
    int len;
    couple start;

    public:
    Circle(std::vector<T> spectre, double x, int i) : t(std::vector<T>()), count(std::vector<int>()), x(x), len(spectre.size()), start(couple(i, 0)) {
        count.push_back(1);
        t.push_back(spectre[0]);
        for (unsigned int ind = 0; ind + 1 < spectre.size(); ind++) {
            if (spectre[ind] == spectre[ind + 1]) {
                count[count.size() - 1]++;
            } else {
                count.push_back(1);
                t.push_back(spectre[ind+1U]);
            }
        }
    }

    int size() {
        return t.size();
    }

    bool is_start(couple end) {
        auto [i, k] = start;
        auto [j, l] = end;
        return i == j;
    }

    couple get_start() {
        return start;
    }

    double get(couple a) {
        auto [i, k] = a;
        return t[i]+ x*k;
    }

    couple get_next(couple a) {
        auto [i, k] = a;
        if (i + 1 == t.size()) {
            return couple(0, k+1);
        }
        return couple(i+1, k);
    }

    couple get_previous(couple a) {
        auto [i, k] = a;
        if (i == 0) {
            return couple(t.size() - 1, k-1);
        }
        return couple(i-1, k);
    }

    int get_count(couple a) {
        auto [i, _] = a;
        return count[i];
    }

    int get_cardinal(couple a1, couple a2) {
        auto [i1, k1] = a1;
        auto [i2, k2] = a2;
        int s = 0;
        int delta = i2 - i1 + (k2 - k1) * t.size();
        int q = delta / t.size();

        for (int i = 0; i < t.size(); i++) {
            int c = q;
            if (i1 > i2) {
                c += (i >= i1 || i <= i2);
            } else {
                c += (i >= i1 && i <= i2);
            }
            s += count[i] * c;
        }
        return s;
    }

    int length() {
        return len;
    }
};

double get_measure(std::vector<double> spectre, double delta, double x, int i);