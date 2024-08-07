import numpy as np
import random as rand
from util import EPSILON, RAD, amin
from kappa import kappa_list, kappa_table
from quantization import find_local_minima, error

# ============= General framework ============= #

class TempoModel():
    def __init__(self, tempo_init) -> None:
        self.tempo = tempo_init
    
    def update_and_return_tempo(self, input, debug=0):
        return


# ============= Score-based models ============= #

class CanonicalTempo(TempoModel):
    def __init__(self, tempo_init=120) -> None:
        super().__init__(tempo_init)

    def update_and_return_tempo(self, input, debug=0):
        beat_input, time_input = input
        return 60 * beat_input / time_input # bpm


class Large():
    def __init__(self, tempo_init=None, phase=0, last_time=0, eta_s = 0.9, eta_phi=np.pi, eta_p=np.pi/4) -> None:
        if tempo_init is None:
            tempo_init = 120 # bpm
        self.period = 60 / tempo_init           # second / beat (default to 120 bpm)
        self.phase = phase                      # in the range [-0.5, 0.5]
        self.kappa = 2.                         # Expectancy parameter for Mises-Von distribution (or variance!)
        self.s_kappa = 0.94                     # Maximum likelihood value approximation of kappa
        self.eta_s = eta_s                      # Propagation parameter for kappa max. likelihood approx. in [0, 1]
        self.last_time = last_time              # Last known event (s)
        self.eta_phi = eta_phi
        self.eta_p = eta_p
        self.phi = 0
        self.dt = 1
    
    def set_tempo(self, t):
        """ Set current tempo """ 
        self.period = 60 / t

    def period_to_tempo(self, period):
        """ Converts a period (sec / beat) to tempo (bpm) """
        return 60 / (period) # bpm

    def get_tempo(self):
        """ Return estimated tempo in bpm """
        return self.period_to_tempo(self.period) # bpm
    
    def normalize_phase(self, phi):
        """ Force phase to fit in the interval [0, 1[ mod 1 """
        return phi - int(phi)

    def F(self, phi, kappa):
        return 1 / (RAD*np.exp(kappa)) * np.exp(kappa * np.cos(RAD * phi)) * np.sin(RAD * phi)

    def update_parameters(self, current_time, phi, debug=0):
        """ Update internal parameters, according to the model equations """
        p = self.period
        kappa = self.kappa

        self.period = p * (1 + self.eta_p * self.F(phi, kappa))
        self.phase += (current_time - self.last_time) / p - self.eta_phi * self.F(phi, kappa)

        # Updating kappa
        # Update error accumulation
        self.s_kappa -= self.eta_s * (self.s_kappa - np.cos(RAD * phi)) # According to equation (7)

        # Update kappa by table lookup
        # The bigger the kappa, the smaller the tempo change.. thus, s_kappa should be big for small tempo changes!
        if (abs(self.s_kappa) <= kappa_table[0]):
            self.kappa = kappa_list[0] #  Bound the likelihood to the min of table
        elif abs(self.s_kappa) > kappa_table[-1]:
            self.kappa = kappa_list[-1] #  Bound the likelihood to the max of table, correspond to a computation of parameter b in equation (7)
        else: # Find the most likely kappa by table lookup
            for i in range(1, len(kappa_table)): # Little modification to source code, to prevent the case i = 0
                if kappa_table[i] >= abs(self.s_kappa):
                    self.kappa = kappa_list[i]
                    break

        self.last_time = current_time

        if debug:
            print("Phi=" + str(self.phase)[:5], "p="+str(self.period)[:5], "Kappa=" + str(kappa)[:5], self.get_tempo(), "BPM")

    def update_and_return_tempo(self, input, debug=0):
        current_beat, current_time = input
        k = int(self.phase - current_beat)
        dphi = -amin(k + current_beat - self.phase, k + 1 + current_beat - self.phase)
        self.phi = dphi
        self.dt = current_time - self.last_time
        self.update_parameters(current_time, dphi, debug=debug)
        return self.get_tempo()


class TimeKeeper(TempoModel):
    def __init__(self, tempo_init=120, a0=0, alpha=0.05, beta=0.05, last_time=0) -> None:
        self.alpha = alpha                  #
        self.beta = beta                    #
        self.tau = 60 / tempo_init          # s (/ beat)
        self.asynchrony = a0                # Initial asynchrony (s)
        self.last_time = last_time          # Last known event (s)
        self.c = self.tau

    def normalize_asynchrony(self, a):
        while a < 0:
            a += self.tau
        while a >= self.tau:
            a -= self.tau

        if a > self.tau / 2:
            a -= self.tau

        if abs(a) < 0.001:
            return 0
        return a

    def update_parameters(self, current_time, asyn, debug=0):
        """ Given the current time (seconds), update the internal parameters """
        # According to : https://www.mcgill.ca/spl/files/spl/loehrlargepalmer2011.pdf
        # Loehr, Large, Palmer (2011)
        tau = self.tau
        c = current_time - self.last_time
        if abs(c) < EPSILON:
            return

        self.asynchrony = asyn * (1 - self.alpha) + tau - c
        #self.asynchrony = self.normalize_asynchrony(self.asynchrony)
        self.tau = tau - self.beta * self.normalize_asynchrony(asyn)
        self.last_time = current_time

        if debug:
            print("A:" + str(self.asynchrony)[:5], "Tau:" + str(self.tau)[:5], int(self.get_tempo()), "BPM")

    def get_tempo(self):
        return 60 / self.tau

    def update_and_return_tempo(self, input, debug=0):
        current_beat, current_time = input
        k = int((self.asynchrony - current_beat) / self.tau)
        asyn = -amin(-self.asynchrony + current_beat + k*self.tau, (k+1)*self.tau - (self.asynchrony - current_beat))
        self.update_parameters(current_time, asyn, debug=debug)
        return self.get_tempo()

# ============= Scoreless models ============= #

class Estimator():
    def __init__(self, accuracy=500, limit=np.sqrt(2), eq_test=0.0001) -> None:
        """ Naive version : no memory """
        self.accuracy = accuracy
        self.limit = limit
        self.dt = abs(limit - 1) / accuracy
        self.eq_test = eq_test

    def dist(self, a, b, abso=0):
        """ Returns the distance (in a mathematical way) between values a and b """
        if abso:
            return abs(a - b)
        return abs(np.log(a / b))

    def new_best(self, current_best, new_value, new_dist):
        if current_best is None or (current_best[1] > self.eq_test and self.dist(new_dist, current_best[1], abso=1) > self.eq_test and new_dist < current_best[1]):
            return (new_value, new_dist)
        return current_best

    def E(self, a):
        """ Returns an estimation as described in the equation """
        assert(a > 0)
        best_try = (1, self.dist(a, 1))

        # Test if a is a power of 2
        log2 = np.floor(np.log2(a))
        for t in (log2, log2+1):
            if abs(t) <= 9:
                b = 2**t
                best_try = self.new_best(best_try, b, self.dist(a, b))

        # Test if 3*a is a power of 2 (triplet, but not only)
        log2 = np.floor(np.log2(3*a))
        for t in (log2, log2+1):
            if abs(t) <= 2 and 0:
                b = (2**t) / 3
                best_try = self.new_best(best_try, b, self.dist(a, b))

        if self.dist(best_try[0], a) < self.eq_test:
            return a # There is an explanation to this change, without tempo consideration
        return best_try[0] # The tempo probably changed
    
    def even_search(self, v1):
        """ Evenly spaced search according to log distance """
        return 1/v1

    def find_solution(self, d1, d2, debug=0):
        """ solve the equation : x = t1 * E(x*t2) """
        t1 = d1/d2
        t2 = d2/d1

        best_try = None
        for i in range(self.accuracy):
            if i == 0:
                values = (1,)
            else:
                v1 = 1 + self.dt * i
                v2 = self.even_search(v1)
                values = (v1, v2)
            for v in values:
                dist_to_solution = self.dist(v, t1 * self.E(v*t2))
                best_try = self.new_best(best_try, v, dist_to_solution)
                if debug:
                    print(v, v*t2, self.E(v*t2))

                if dist_to_solution < self.eq_test:
                    return best_try[0]

        return best_try[0]


class AbsoluteEstimator(Estimator):
    def even_search(self, v1):
        """ Evenly spaced search according to absolute distance """
        return 2 - v1


class RandomEstimator(Estimator):
    def find_solution(self, d1, d2, debug=0):
        c1 = rand.random() * (self.limit - 1)
        c2 = 1/c1
        return rand.choice([c1, c2])


class TempoTracker(TempoModel):
    """ General model using an Estimator """
    def __init__(self, estimator, tempo_init, init_time=0) -> None:
        super().__init__(tempo_init)
        self.estimator = estimator
        self.last_time = None
        self.current_time = init_time

    def set_tempo(self, t):
        self.tempo = t

    def get_tempo(self):
        return self.tempo

    def update_and_return_tempo(self, next_time, debug=0):
        if self.last_time is not None:
            delta_1 = self.current_time - self.last_time
            delta_2 = next_time - self.current_time

            x = self.estimator.find_solution(delta_1, delta_2, debug=debug)
            if debug:
                print(x)
            self.tempo *= x

        self.last_time = self.current_time
        self.current_time = next_time
        return self.get_tempo()


class PolyphonicTempoTracker(TempoTracker):
    """ Polyphonic adaption of TempoTracker to work with durations instead of onsets """
    def update_and_return_tempo(self, next_duration, debug=0):
        if self.last_time is not None:
            x = self.estimator.find_solution(self.last_time, next_duration, debug=debug)
            if debug:
                print(x)
            self.tempo *= x

        self.last_time = next_duration
        return self.get_tempo()


class QuantiTracker(TempoModel):
    def __init__(self, tempo_init, init_time=0) -> None:
        self.paths = []
        self.i = None
        self.tempo_init = tempo_init
        self.tempo = None
        self.last_time = None
        self.current_time = init_time
        self.T_min = 10 # bm / s
        self.T_max = 240*2 + 5 # bm / s
        self.quarter_in_bm = 60 # a quarter is 60 bm here
        self.mins = []
        self.T = []
    
    def get_interval(self):
        return self.T_min, self.T_max
    
    def get_possible_tempi(self):
        return [(1/i[0], i[1]) for i in self.paths] # quarter / m
    
    def get_tempo(self, change=0):
        if self.i is None:
            return self.tempo_init / self.quarter_in_bm * 60
        #self.i = np.argmin([k[1] / k[0] for k in self.paths])
        if change:
            self.i = (self.i + 1) % len(self.paths)
        return (1/self.paths[self.i][0]) / self.quarter_in_bm * 60 # quarter / m
    
        return np.max([i[1] for i in self.paths])
    
    def tempo_distance(self, t, t2):
        return abs(np.log(t / t2))

    def find_nearest(self, mins, const):
        i = 0
        best = d = self.tempo_distance(mins[0], const)
        for m in range(1, len(mins)):
            d2 = self.tempo_distance(mins[m], const)
            if d2 > d:
                return i, best
            d = d2
            if d < best:
                best = d
                i = m

        return i, best

    def filter(self, mins, T, conds):
        """ Filter the semi-strict minima according to the conditions indicated as integers in conds
            1 and 2 indicate repectively the conditions 1 and 2 described in the report
            3 indicates that the function is the symbolic error instead of the transcription error for the previous conditions
        """
        loc_error = lambda a : error(a, T)
        if 3 in conds:
            loc_error = lambda a : error(a, T)/a

        if len(mins) < 3 and len(conds) > 0:
            if len(mins) <= 1 or loc_error(mins[0]) == loc_error(mins[-1]):
                return mins
            a = loc_error(mins[0])
            b = loc_error[mins[1]]
            if a > b:
                return [mins[1]]
            return [mins[0]]

        if 1 in conds:
            filtered = []
            for i in range(1, len(mins) - 1):
                if loc_error(mins[i-1]) >= loc_error(mins[i]) and loc_error(mins[i+1]) >= loc_error(mins[i]):
                    filtered.append(mins[i])
            mins = filtered

        if 2 in conds:
            if len(mins) < 3:
                if len(mins) <= 1 or loc_error(mins[0]) == loc_error(mins[-1]):
                    return mins
                a = loc_error(mins[0])
                b = loc_error[mins[1]]
                if a > b:
                    return [mins[1]]
                return [mins[0]]

            filtered = []
            min_err = loc_error(mins[0])
            for i in range(1, len(mins) - 1):
                if loc_error(mins[i]) <= min_err:
                    min_err = loc_error(mins[i])
                    filtered.append(mins[i])
            mins = filtered

        return mins

    def update_and_return_tempo(self, next_time, debug=0):
        is_grace = False
        if self.last_time is not None:
            delta_1 = self.current_time - self.last_time
            delta_2 = next_time - self.current_time
            T = (delta_1, delta_2)
            self.T = T

            if delta_2 > EPSILON and delta_1 > EPSILON:
                mins = find_local_minima(T, 1/self.T_max, 1/self.T_min)
                mins = self.filter(mins, T, conds=[])

                if debug and len(mins) == 0:
                    print(len(mins), T, (1/self.T_max, 1/self.T_min))

                if len(mins) <= 0:
                    return self.get_tempo()
                self.mins = [(1/a, error(a, T)) for a in mins]

                if self.i is None or len(self.paths) == 0:
                    self.paths = [(m, 0) for m in mins]
                    self.i = self.find_nearest(mins, 1/self.tempo_init)[0]
                else:
                    j = 0
                    for i in range(len(self.paths)):
                        if i == 0 or (self.paths[i][0] != self.paths[i-1][0]):
                            dj, d = self.find_nearest(mins[j:], self.paths[i][0])
                            j += dj
                        self.paths[i] = (mins[j], d + self.paths[i][1])

                tempo = self.get_tempo(change=False)
                is_grace = int(delta_2 * tempo) == 0
        
        if next_time - self.current_time > EPSILON and not is_grace:
            self.last_time = self.current_time
            self.current_time = next_time

        return self.get_tempo()