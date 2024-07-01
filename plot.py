import numpy as np
import matplotlib.pyplot as plt

def f(a, t) :
    return t/a - int(t/a)

def g(a, t) :
    return min(f(a, t), 1 - f(a, t))

def k(a, T):
    return a * np.max([g(a, t) for t in T])

T = np.array([0.98, 1.52, 0.89])
tau = 0.1
x = np.arange(2*tau, (np.min(T) + tau)*2, 0.001) # step at 1ms
y = [(lambda t : k(a, t))(T) for a in x]

#tmp = [[t/(k + 0.5) for k in np.arange(1, int(t/(2*tau))+1, 1)] for t in T]
tmp = [(t1 + t2) / k for t1 in T for t2 in T if t2 < t1 for k in range(1, int((t1+t2)/(2*tau)) + 1)]
colors = ['lightgray', 'red', 'blue']
plt.xscale("log")
for a in range(len(tmp)):
    #for l in tmp[a]:
        #plt.axvline(x=l, color=colors[a], markersize=1, label="c")
    plt.axvline(x=tmp[a], color=colors[0], markersize=1, label='c')

plt.plot(x, y, '.', markersize=2)
plt.show()