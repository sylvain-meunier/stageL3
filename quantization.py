import numpy as np

def find_local_minima(T, start, end):
    assert(len(T) > 0)

    maxs = [t / (k+0.5) for t in T for k in range(int(t/end), int(t/start)+1)] # According to caracterization
    maxs.sort()
    potentials = [(t1+t2) / k for t1 in T for t2 in T for k in range(max(1, int((t1+t2)/end)), int((t1+t2)/start)+1) if t1 < t2]
    potentials.sort() # Only a necessary condition

    if len(potentials) == 0: # Implies : T = {T[0]}
        potentials = [T[0]/k for k in range(int(T[0]/end), int(T[0]/start)+1)[::-1]] # Already sorted
        mins = potentials # In this specific case, the condition is an equivalence
    else:
        j = 0
        mins = []
        for i in range(len(maxs)-1):
            pot_mins = []
            while j < len(potentials) and maxs[i] <= potentials[j] < maxs[i+1] :
                pot_mins.append(potentials[j])
                j += 1
            if len(pot_mins) > 0:
                mins.append(np.min(pot_mins))

    mins.sort(reverse=1)
    return mins

def f(a, t) :
    return t/a - int(t/a)

def g(a, t) :
    return min(f(a, t), 1 - f(a, t))

def error(a, T):
    return a * np.max([g(a, t) for t in T])
