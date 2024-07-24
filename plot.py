import numpy as np
from quantization import find_local_minima, error
import matplotlib.pyplot as plt
from util import EPSILON
import matplotlib.pylab as pylab

def f(a, t) :
    return t/a - int(t/a)

def g(a, t) :
    return min(f(a, t), 1 - f(a, t))

def k(a, T):
    return a * np.max([g(a, t) for t in T])

def plot1():
    T = np.array([0.98, 1.52])
    tau = 0.1
    x = np.arange(2*tau, (np.min(T) + tau)*2, 0.001) # step at 1ms
    y = [(lambda t : k(a, t))(T) for a in x]

    tmp = [[t/(k + 0.5) for k in np.arange(1, int(t/(2*tau))+1, 1)] for t in T]
    #tmp = [(t1 + t2) / k for t1 in T for t2 in T if t2 < t1 for k in range(1, int((t1+t2)/(2*tau)) + 1)]
    colors = ['lightgray', 'red', 'blue']
    plt.xscale("log")
    for a in range(len(tmp)):
        for l in tmp[a]:
            plt.axvline(x=l, color=colors[a], markersize=1, label="c")
        #plt.axvline(x=tmp[a], color=colors[0], markersize=1, label='c')

    plt.plot(x, y, '.', markersize=2)
    plt.show()

def plot2():
    T = np.array([0.98, 1.52])
    tau = 0.01
    start = 2*tau
    end = 3*tau
    x = np.arange(start, end, (end-start)/100000) # step at 1ms
    y = [error(a, T) for a in x]

    tmp = find_local_minima(T, start, end)
    plt.xscale("log")
    for a in range(len(tmp)):
        plt.axvline(x=tmp[a], color="lightgray", markersize=1, label='c')

    plt.plot(x, y, '.', markersize=2)
    plt.show()

def canonical(score, perf, n, default=120):
    if (perf[n+1] - perf[n]) > EPSILON:
        return 60 * (score[n+1] - score[n]) / (perf[n+1] - perf[n])
    return default

def th_delta(t1, t2):
    return abs(1 / t1 - 1/t2)


def plot_castle():
    #plt.rcParams['axes.facecolor'] = 'gray'

    size = 35
    params = {'legend.fontsize': size,
        'axes.labelsize': size,
        'axes.titlesize':size,
        'xtick.labelsize':20,
        'ytick.labelsize':20}
    pylab.rcParams.update(params)

    perf = [1.757, 2.330, 2.534, 2.924, 3.296, 3.669, 4.080, 4.649, 4.846, 5.274, 5.650, 6.013, 6.424]
    t1 = [1, 2.5, 3, 4, 5, 6, 7, 8.5, 9, 10, 11, 12, 13]
    t2 = [1.1875, 2.775, 3.25, 4.125, 5.25, 6.25, 7.45, 9, 9.375, 10.416667, 11.375, 12.375, 13]
    c1 = []
    c2 = []

    for i in range(len(perf) - 1):
        c1.append(canonical(t1, perf, i))
        c2.append(canonical(t2, perf, i))

    dist = [abs(np.log(c1[i] / c2[i])) for i in range(len(c1))]

    
    #plt.plot(perf[:-1], c1, '*', color="white", markersize=8, label="Tempo curve A")
    #plt.plot(perf[:-1], c2, '.', color="black", markersize=8, label="Tempo curve B")
    #plt.plot(perf[:-1], dist, '-', color="black", markersize=8, label="Tempo distance")
    #plt.plot((perf[0], perf[-2]), [EPSILON, EPSILON], '-', color="red", label="Human ability treshold")
    plt.plot(perf[:-1], [th_delta(c1[i], c2[i]) for i in range(len(c1))], '--', color="black", markersize=8, label="Theorical distance")
    plt.xlabel("Time (s)")
    plt.ylabel("Tempo distance (log)")
    plt.legend()
    plt.show()

plot_castle()