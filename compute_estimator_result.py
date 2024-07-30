import numpy as np
from pic import load_from_txt
from plot import biglabels
from util import EPSILON, path, get_composer
import matplotlib.pyplot as plt
file = "./Performance/" + "poly_performance_025.txt"

load = load_from_txt(file) + [(path + "//", 0)]
t = []

biglabels()
size = 10
fig, ax = plt.subplots()


for l in load:
    composer = get_composer(l[0])
    if len(t) == 0 or composer != current_composer:
        if len(t) > 0:
            a = np.array(t[-1])
            med = np.median(a)
            mea = np.mean(a)
            mi = np.min(a)
            ma = np.max(a)
            if len(t) == 1:
                plt.plot([current_composer, current_composer], [mi, ma], color="orange", markersize=2, label="Polyphonic")
                plt.plot([current_composer], [med], '.', color="red", markersize=size, label='Median')
                plt.plot([current_composer], [mea], '*', color="black", markersize=size, label='Mean')
                plt.plot([current_composer], [ma], 'v', color="black", markersize=size, label='Max')
                plt.plot([current_composer], [mi], '^', color="black", markersize=size, label='Min')
            else:
                plt.plot([current_composer, current_composer], [mi, ma], color="orange", markersize=2)
                plt.plot([current_composer], [med], '.', color="red", markersize=size)
                plt.plot([current_composer], [mea], '*', color="black", markersize=size)
                plt.plot([current_composer], [ma], 'v', color="black", markersize=size)
                plt.plot([current_composer], [mi], '^', color="black", markersize=size)
        current_composer = composer
        t.append([])
    t[-1].append(l[1])

t = []
file = "./Performance/" + "performance_025.txt"
load = load_from_txt(file) + [(path + "//", 0)]
for l in load:
    composer = get_composer(l[0])
    if len(t) == 0 or composer != current_composer:
        if len(t) > 0:
            a = np.array(t[-1])
            med = np.median(a)
            mea = np.mean(a)
            mi = np.min(a)
            ma = np.max(a)
            if len(t) == 1:
                plt.plot([current_composer, current_composer], [mi, ma], color="blue", markersize=2, label="Monophonic")
            else:
                plt.plot([current_composer, current_composer], [mi, ma], color="blue", markersize=2)

            plt.plot([current_composer], [med], '.', color="red", markersize=size)
            plt.plot([current_composer], [mea], '*', color="black", markersize=size)
            plt.plot([current_composer], [ma], 'v', color="black", markersize=size)
            plt.plot([current_composer], [mi], '^', color="black", markersize=size)
        current_composer = composer
        t.append([])
    t[-1].append(l[1])

plt.xticks(rotation=50)
plt.yticks(np.linspace(0, 1, 11))


fig.set_layout_engine(layout="tight")
plt.legend()
plt.show()