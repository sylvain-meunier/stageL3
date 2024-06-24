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
    Circle(std::vector<T> spectre, double x, int i) : t(std::vector<double>(spectre)), count(std::vector<int>()), x(x), len(t.size()), start(couple(i, 0)) {
        count.push_back(1);
        int ind = 0;
        while (ind + 1 < t.size()) {
            if (t[ind] == t[ind + 1]) {
                t.erase(t.begin() + ind+1);
                count[count.size() - 1] += 1;
            } else {
                count.push_back(1);
                ind++;
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

        if (k1 == k2) {
            for (int i = 0; i < t.size(); i++) {
                int c = fmax(0, k2-k1-1);
                c += (i >= i1 && i <= i2);
                s += count[i] * c;
            }
        } else {
            for (int i = 0; i < t.size(); i++) {
                int c = fmax(0, k2-k1-1);
                c += (i >= i1 || i <= i2);
                s += count[i] * c;
            }
        }
        return s;
    }

    int length() {
        return len;
    }
};

double get_measure(std::vector<double> spectre, double delta, double x, int i);