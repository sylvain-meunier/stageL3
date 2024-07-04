# Adapted from Large & Jones (1999) : https://research.ebsco.com/c/glmwyg/viewer/pdf/24oxihnocr?route=details
import scipy
import numpy as np
import scipy.special
from util import EPSILON
from py_measure import cpp_measure
from kappa import kappa_list, kappa_table
from quantization import find_local_minima
import random as rand

RAD = np.pi * 2

def normalize_tempo(tempo, min=60, max=120):
    """ All usual tempos can be expressed as a unique value of (60, 120],  """
    while tempo > max:
        tempo /= 2
    while tempo < min:
        tempo *= 2
    return tempo


class T_Tempo():
    def __init__(self) -> None:
        self.kappa = 2.                     # Expectancy parameter for Mises-Von distribution (or variance!)
        self.s_kappa = 0.94                 # Maximum likelihood value approximation of kappa
        self.eta_s = 0.9                    # Propagation parameter for kappa max. likelihood approx.
        self.rt_tempo = 1.                  # Realtime estimated tempo (second / beat)
        self.tempo_correction = 0.          # Tempo correction value at each step
        self.min_kappa = 1.                 # Minimum KAPPA value not to bypass (to manually limit tempo variation)
        self.nb_beat = 4

    def set_nb_beat(self, nb_beat):
        self.nb_beat = nb_beat

    def period(self):
        # Converts tempo to period
        return self.rt_tempo * self.nb_beat

    def wrap_phi(self, time_event):
        """ Return the phase corresponding to the time_event, according to the current period (ie estimated tempo) """
        p = self.period()
        while (time_event < 0):
            time_event += p
        while (time_event > p):
            time_event -= p
        ratio = time_event / p
        if ratio > 0.5:
            return ratio - 1
        return ratio # phi mod[-0.5, 0.5] 1

    def get_tempo(self):
        return 60 * self.rt_tempo # beat per minute

    def init(self):
        self.tempo_correction=0.
        self.kappa=2.
        self.s_kappa=0.

    def reset(self):
        """ Reset internal tempo states. Example of use : BPM initialization """
        self.tempo_correction = 0.
        self.kappa  = 2.
        self.s_kappa  = 0.94

    def tempo_update(self, new_tempo):
        """ Update the tempo """
        assert (new_tempo > 0)
        self.rt_tempo = new_tempo

    def entrain(self, phi, kappa):
        """ Entrainement Function based on Mises-Von first derivative distribution """
        return (1.0/(2.0*np.pi*np.exp(kappa))) * np.exp(kappa * np.cos(2.0*np.pi*phi))*np.sin(2.0*np.pi*phi)
    
    def tempo0sc(self, passed_beat, score_tempo, x_elapsedrealtime):
        """ Mono-tonic tempo update oscillator based on Large & Jones.
        @passed_beat       passed beat time in the score
        @score_tempo       Tempo in the score
        @x_elapsedrealtime       Passed absolute time (seconds)
        @verbosity        verbosity flag for debugging
        @Result : update internal tempo
        """
        assert(self.rt_tempo > 0.)
        assert(passed_beat > 0.)
        assert(score_tempo > 0.)
        assert(x_elapsedrealtime >= 0.)

        rt_beat = x_elapsedrealtime / self.rt_tempo * self.period()
        phi_diff = self.wrap_phi(rt_beat)

        # Correct the difference based on score progression (our advantage to Large!)
        if (rt_beat >= passed_beat):
            if (phi_diff < 0):
                phi_diff *= -1
        elif phi_diff > 0:
            phi_diff *= -1

        # Update error accumulation
        self.s_kappa = self.s_kappa - self.eta_s * (self.s_kappa - np.cos(2*np.pi * phi_diff))

        # Update kappa by table lookup
        # The bigger the kappa, the smaller the tempo change.. thus, s_kappa should be big for small tempo changes!
        if (abs(self.s_kappa <= kappa_table[0])):
            self.kappa = kappa_list[0] #  Bound the likelihood to the min of table
        elif abs(self.s_kappa > kappa_table[-1]):
            self.kappa = kappa_list[-1] #  Bound the likelihood to the max of table
        else: # Find the most likely kappa by table lookup
            for i in range(1, len(kappa_table)): # Little modification to source code, to prevent the case i = 0
                if kappa_table[i] >= abs(self.s_kappa):
                    self.kappa = kappa_list[i - 1]
                    break

        # Apply MIN filter
        self.kappa = max(self.kappa, self.min_kappa)

        # Update realtime tempo
        self.tempo_correction = self.entrain(phi_diff, self.kappa)
        new_rt_tempo = self.rt_tempo * (1. + self.tempo_correction)

        assert(new_rt_tempo >= 0)
        self.tempo_update(new_rt_tempo)


class T_Tempo_Var(T_Tempo):
    def init_var(self, temp_init = 60.): # name_mangling on init method, only way to translate the equivalent c++ code
        self.init()     # method of ancestor T_Tempo
        self.tempo_init = temp_init # bpm
        self.last_time = 0
        self.rt_tempo  = self.tempo_init / 60

    def TempoUpdate(self, tempo_spb):
        assert (tempo_spb > 0)
        self.rt_tempo = tempo_spb


    def set_tempo(self, beats):
        self.rt_tempo = 60. / beats

    def tempo0sc_var(self, now): # name_mangling on init method, only way to translate the equivalent c++ code
        x_elapsedrealtime = now - self.last_time
        if (x_elapsedrealtime > 0):
            # method of ancestor T_Tempo
            self.tempo0sc(self.period(), self.rt_tempo, x_elapsedrealtime)
        self.last_time = now
        return self.get_tempo()


# My implementation of Large & Jones, based on their equations
class Oscillateur2():
    def __init__(self, tempo_init=None, phase=0, min_kappa=1, last_time=0, eta_s = 0.9, eta_phi=np.pi, eta_p=np.pi/4) -> None:
        if tempo_init is None:
            tempo_init = 120 # bpm
        self.period = 60 / tempo_init           # second / beat (default to 120 bpm)
        self.phase = phase                      # in the range [-0.5, 0.5]
        self.kappa = 2.                         # Expectancy parameter for Mises-Von distribution (or variance!)
        self.s_kappa = 0.94                     # Maximum likelihood value approximation of kappa
        self.eta_s = eta_s                      # Propagation parameter for kappa max. likelihood approx. in [0, 1]
        self.min_kappa = min_kappa              # Minimum KAPPA value not to bypass (to manually limit tempo variation)
        self.last_time = last_time              # Last known event (s)
        self.eta_phi = eta_phi
        self.eta_p = eta_p
        self.nb_beat = 4                        # Potentially new and useful variable, to determine if score is not available
        self.error = 0

    def get_tempo(self):
        """ Return estimated tempo in bpm """
        return 60 / self.period # bpm
    
    def normalize_phase(self):
        """ Force phase to fit in the interval (-0.5, 0.5] mod 1 """
        self.phase = self.phase - np.floor(self.phase)
        while self.phase < 0: # Should not happen
            self.phase += 1

        while self.phase > 0.5: # Should happen at most once
            self.phase -= 1

    def F(self, phi, kappa):
        return 1 / (RAD*np.exp(kappa)) * np.exp(kappa * np.cos(RAD * phi)) * np.sin(RAD * phi)
    
    def update_parameters2(self, current_time, debug=0, period_coupling=0, phase_coupling=0):
        p = self.period
        phi = self.phase
        self.eta_phi = 2
        self.eta_p = 0.4

        self.phase = phi + (current_time - self.last_time) / p - self.eta_phi / RAD * np.sin(RAD * phi) + phase_coupling
        self.normalize_phase()
        self.period = p*(1 + self.eta_p / RAD * np.sin(RAD * phi)) + period_coupling
        self.last_time = current_time

        if debug:
            print("Phi=" + str(self.phase)[:5], "p="+str(self.period)[:5], self.get_tempo(), "BPM")

    def update_parameters(self, current_time, debug=0, phase_coupling_value=0, period_coupling_value=0):
        """ Update internal parameters, according to the model equations """
        p = self.period
        phi = self.phase
        kappa = self.kappa
        #self.eta_phi = 1  / scipy.special.i0(kappa) * np.exp(kappa * np.cos(RAD * phi))

        self.period = p * (1 + self.eta_p * self.F(phi, kappa)) + period_coupling_value
        self.phase = phi + (current_time - self.last_time) / p - self.eta_phi * self.F(phi, kappa) + phase_coupling_value
        self.normalize_phase()

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

        self.kappa = max(self.kappa, self.min_kappa)
        self.last_time = current_time

        if debug:
            print("Phi=" + str(self.phase)[:5], "p="+str(self.period)[:5], "Kappa=" + str(kappa)[:5], self.get_tempo(), "BPM")

    def update_and_return_tempo(self, current_time, debug=0, iter=1, kappa=True):
        current_time += self.error
        delta = current_time - self.last_time
        if 0:
            iter += 10 - int(self.kappa)
        for i in range(iter):
            if kappa:
                self.update_parameters(current_time + delta*i, debug=debug)
            else:
                self.update_parameters2(current_time + delta * i, debug=debug)
        self.error += delta * (iter-1)
        return self.get_tempo()


class TimeKeeper():
    def __init__(self, tempo_init=120, a0=0, alpha=0.05, beta=0.05, last_time=0) -> None:
        self.alpha = alpha                  #
        self.beta = beta                    #
        self.tau = 60 / tempo_init          # s (/ beat)
        self.asynchrony = a0                # s
        self.last_time = last_time
        self.c = self.tau

    def normalize_asynchrony(self):
        while self.asynchrony < 0:
            self.asynchrony += self.tau
        while self.asynchrony >= self.tau:
            self.asynchrony -= self.tau

        if self.asynchrony > self.tau / 2:
            self.asynchrony -= self.tau

        if abs(self.asynchrony) < 0.001:
            self.asynchrony = 0

    def update_parameters(self, current_time, debug=0):
        """ Given the current time (seconds), update the internal parameters """
        # According to : https://www.mcgill.ca/spl/files/spl/loehrlargepalmer2011.pdf
        # Loehr, Large, Palmer (2011)
        asyn = self.asynchrony
        tau = self.tau
        c = current_time - self.last_time
        if abs(c) < 0.001:
            c = tau

        self.asynchrony = asyn * (1 - self.alpha) + tau - c
        self.normalize_asynchrony()
        self.tau = tau - self.beta * asyn
        self.last_time = current_time

        if debug:
            print("A:" + str(self.asynchrony)[:5], "Tau:" + str(self.tau)[:5], int(self.get_tempo()), "BPM")

    def get_tempo(self):
        return 60 / self.tau

    def update_and_return_tempo(self, current_time, debug=0):
        self.update_parameters(current_time, debug=debug)
        return self.get_tempo()


# My implementation of Large & Jones, based on their equations
class Oscillateur():
    def __init__(self, tempo_init=None, phase=0, min_kappa=1, last_time=0, eta_phi=1, eta_p=1, eta_s = 0.9) -> None:
        if tempo_init is None:
            tempo_init = 120
        self.period = 60 / tempo_init           # second / beat (default to 120 bpm)
        self.phase = phase                      # in the range [-0.5, 0.5]
        self.s_kappa = 0.94
        self.kappa = 2.                         # Expectancy parameter for Mises-Von distribution (or variance!)
        self.eta_s = eta_s                      # Propagation parameter for kappa max. likelihood approx. in [0, 1]
        self.last_time = last_time              # Last known event (s)
        self.eta_phi = eta_phi
        self.eta_p = eta_p
        self.nb_beat = 4                        # Potentially new and useful variable, to determine if score is not available
        self.min_kappa = min_kappa
        self.error = 0                          # Error caused by iterations of same IOI to accelerate stabilisation

    def reset(self, phase=0, s_kappa=0.94, tempo_init=120, kappa=2, last_time=0):
        self.phase = phase
        self.error = 0
        self.s_kappa = s_kappa
        self.period = 60 / tempo_init
        self.kappa = kappa
        self.last_time = 0

    def set_nb_beat(self, nb_beat):
        self.nb_beat = nb_beat

    def get_tempo(self):
        """ Return estimated tempo in bpm """
        return 60 / self.period # bpm
    
    def normalize_phase(self, phi):
        """ Force phase to fit in the interval (-0.5, 0.5] mod 1 """
        phi -= np.floor(phi)
        while phi < 0: # Should not happen
            phi += 1

        while phi > 0.5: # Should happen at most once
            phi -= 1
        return phi

    def entrain(self, phi, kappa):
        """ Entrainement Function based on Mises-Von first derivative distribution """
        return (1.0/(2.0*np.pi*np.exp(kappa))) * np.exp(kappa * np.cos(2.0*np.pi*phi))*np.sin(2.0*np.pi*phi)
    
    def consider_score(self, phi, current_time, p):
        if ((current_time - self.last_time) >= p):
            if (phi < 0):
                return -phi
        elif phi > 0:
            return -phi
        return phi

    def update_parameters(self, n, score_phase, current_time, debug=0):
        """ Update internal parameters, according to the model equations """
        phi = (self.phase - score_phase)
        p = self.period # Update the period according to the expected next IOI (double, etc...)

        phi = self.consider_score(phi, current_time, p)

        # Updating kappa
        # Update error accumulation
        self.s_kappa -= self.eta_s * (self.s_kappa - np.cos(RAD * phi)) # According to equation (7)

        # Update kappa by table lookup
        # The bigger the kappa, the smaller the tempo change.. thus, s_kappa should be big for small tempo changes!
        if (abs(self.s_kappa <= kappa_table[0])):
            self.kappa = kappa_list[0] #  Bound the likelihood to the min of table
        elif abs(self.s_kappa > kappa_table[-1]):
            self.kappa = kappa_list[-1] #  Bound the likelihood to the max of table, correspond to a computation of parameter b in equation (7)
        else: # Find the most likely kappa by table lookup
            for i in range(1, len(kappa_table)): # Little modification to source code, to prevent the case i = 0
                if kappa_table[i] >= abs(self.s_kappa):
                    self.kappa = kappa_list[i]
                    break

        self.phase += (current_time - self.last_time) / p + self.eta_phi * self.entrain(phi, self.kappa)
        self.phase = self.normalize_phase(self.phase)

        self.period *= 1 + self.eta_p * self.entrain(phi, self.kappa)
        self.last_time = current_time

        if debug:
            print(int(self.get_tempo()), "BPM ; Kappa :", self.kappa, " ; Phase :", str(self.phase)[:5], "(" + str(self.phase - phi)[:5] + ")")
    
    def average(self, v1, v2, n):
        """ Returns a certain average of values v1 and v2, according to n and advantaging v1 """
        return np.exp((np.log(v1) * (n-1) + np.log(v2)) / n)

    def update_and_return_tempo(self, score_beat, current_time, accuracy=10, debug=0, iter=1):
        current_time += self.error
        delta = current_time - self.last_time
        n = find_minimal_integer_ratio(score_beat - np.floor(score_beat))
        for _ in range(iter):
            if delta > EPSILON:
                prev_p = self.period
                prev_phase = self.phase
                last_time = self.last_time
                # In this case, since the unit of score_beat is beat, the theorical period is exactly 1 beat. Thus, this formula gives the theoric (or expected) phase
                score_phase = (score_beat / 1)
                score_phase = score_phase - np.floor(score_phase) # Mod 1
                score_phase = fit_to_accuracy(accuracy, score_phase)
                self.update_parameters(n, score_phase, current_time, debug=debug)
                self.phase = fit_to_accuracy(accuracy, self.phase)

                #self.period = self.average(prev_p, self.period, n)
                current_time += delta
        self.error += delta * (iter-1)
        return self.get_tempo()


class TempoModel():
    def __init__(self, ratio, alpha, tempo_init, min_kappa=1) -> None:
        self.alpha = alpha
        self.ratio = ratio
        self.osc1 = Oscillateur(tempo_init=tempo_init, min_kappa=min_kappa)
        self.osc2 = Oscillateur(tempo_init=tempo_init * self.ratio, min_kappa=min_kappa)

    def update_and_return_tempo(self, score_beat, current_time, debug=0, iter=1):
        o1 = self.osc1
        o2 = self.osc2
        o2.period += -self.alpha * (o2.period - o1.period / self.ratio)
        o1.period += -self.alpha * (o1.period - o2.period * self.ratio)
        t1 = o1.update_and_return_tempo(score_beat / 1, current_time, debug=debug, iter=iter)
        t2 = o2.update_and_return_tempo(score_beat * self.ratio / 1, current_time, debug=debug, iter=iter)
        return (t1 + t2 / self.ratio) / 2


class BeatKeeper():
    def __init__(self, tempo_init=120, phase=0, min_kappa=1, last_time=0, eta_phi=1, eta_s = 0.9) -> None:
        self.period = 60 / tempo_init           # second / beat (default to 120 bpm)
        self.phase = phase                      # in the range [-0.5, 0.5]
        self.s_kappa = 0.94
        self.kappa = 2.                         # Expectancy parameter for Mises-Von distribution (or variance!)
        self.eta_s = eta_s                      # Propagation parameter for kappa max. likelihood approx. in [0, 1]
        self.last_time = last_time              # Last known event (s)
        self.eta_phi = eta_phi
        self.min_kappa = min_kappa
        self.error = 0                          # Error caused by iterations of same IOI to accelerate stabilisation
        self.prev_phase = self.phase
        self.prev_p = self.period


    def reset(self, phase=0, s_kappa=0.94, tempo_init=120, kappa=2, last_time=0):
        self.phase = self.prev_phase = phase
        self.error = 0
        self.s_kappa = s_kappa
        self.period = self.prev_p = 60 / tempo_init
        self.kappa = kappa
        self.last_time = last_time

    def get_tempo(self):
        """ Return estimated tempo in bpm """
        return 60 / self.period # bpm
    
    def normalize_phase(self, phi):
        """ Force phase to fit in the interval (-0.5, 0.5] mod 1 """
        phi -= np.floor(phi)
        while phi < 0: # Should not happen
            phi += 1

        if phi > 0.5:
            phi -= 1
        return phi

    def entrain(self, phi, kappa):
        """ Entrainement Function based on Mises-Von first derivative distribution """
        return (1.0/(RAD*np.exp(kappa))) * np.exp(kappa * np.cos(RAD*phi))*np.sin(RAD*phi)

    def average(self, v1, v2):
        return np.exp((np.log(v1) + np.log(v2)) / 2)

    def update_parameters(self, current_time, debug=0):
        """ Update internal parameters, according to the model equations """
        phi = self.phase
        p = self.period

        if (current_time - self.last_time >= p):
            if (phi < 0):
                phi *= -1
        elif phi > 0:
            phi *= -1

        # Updating kappa
        # Update error accumulation
        self.s_kappa -= self.eta_s * (self.s_kappa - np.cos(RAD * phi)) # According to equation (7)

        # Update kappa by table lookup
        # The bigger the kappa, the smaller the tempo change.. thus, s_kappa should be big for small tempo changes!
        if (abs(self.s_kappa <= kappa_table[0])):
            self.kappa = kappa_list[0] #  Bound the likelihood to the min of table
        elif abs(self.s_kappa > kappa_table[-1]):
            self.kappa = kappa_list[-1] #  Bound the likelihood to the max of table, correspond to a computation of parameter b in equation (7)
        else: # Find the most likely kappa by table lookup
            for i in range(1, len(kappa_table)): # Little modification to source code, to prevent the case i = 0
                if kappa_table[i] >= abs(self.s_kappa):
                    self.kappa = kappa_list[i]
                    break

        self.kappa = max(self.kappa, self.min_kappa)

        dt = (current_time - self.last_time)
        self.phase = phi + dt/p + self.eta_phi * self.entrain(phi, self.kappa)
        self.phase = self.normalize_phase(self.phase)
        self.period /= 1 - p * self.eta_phi * self.entrain(phi, self.kappa) / dt
        self.last_time = current_time
        self.prev_p = p
        self.prev_phase = phi

        if debug:
            print(int(self.get_tempo()), "BPM ; Kappa :", self.kappa, " ; Phase :", str(self.phase)[:5], "(" + str(self.phase - phi)[:5] + ")")

    def update_and_return_tempo(self, current_time, accuracy=10, debug=0, iter=1):
        current_time += self.error
        delta = current_time - self.last_time
        for _ in range(iter):
            if delta > EPSILON:
                self.update_parameters(current_time, debug=debug)
                self.phase = fit_to_accuracy(accuracy, self.phase)
                current_time += delta
        self.error += delta * (iter-1)
        return self.get_tempo()

class Oscillateur_absolute(Oscillateur):
    def normalize_phase(self, phi):
        return phi
    def consider_score(self, phi, current_time, p):
        return phi

class LargeKeeper(Oscillateur_absolute):
    def __init__(self, tempo_init=None, phase=0, min_kappa=1, last_time=0, eta_phi=1, eta_p=1, eta_s=0.9) -> None:
        super().__init__(tempo_init, phase, min_kappa, last_time, eta_phi, eta_p, eta_s)
        self.previous_time = None
        self.previous_phase = 0
    
    def get_tempo(self):
        if self.previous_time is None:
            self.previous_time = self.last_time
            self.previous_phase = self.phase
            return super().get_tempo()
        delta_t = self.last_time - self.previous_time
        delta_phi = self.phase - self.previous_phase + int(self.last_time / self.period) - int(self.previous_time / self.period)
        if delta_t < EPSILON:
            return super().get_tempo()
        self.previous_phase = self.phase
        self.previous_time = self.last_time
        tempo = 60 * delta_phi / delta_t # bpm
        return tempo

def fit_to_accuracy(acc, value):
    return int(value * acc) / acc

def find_minimal_integer_ratio(ratio, precision=0.0001):
    """ Returns the lesser integer n such that n*ratio is an integer  """
    for i in range(1, 8*3+1):
        if abs(i * ratio - int(i*ratio)) < precision:
            return i
    return 1

class Estimator():
    def __init__(self, accuracy=1800, limit=4/3, eq_test=0.0001) -> None:
        """ naive version : no memory """
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

        # Test if 3*a is a power of 2 (triolet, but not only)
        log2 = np.floor(np.log2(3*a))
        for t in (log2, log2+1):
            if abs(t) <= 2 and 0:
                b = (2**t) / 3
                best_try = self.new_best(best_try, b, self.dist(a, b))

        if self.dist(best_try[0], a) < self.eq_test:
            return a # There is an explanation to this change, without tempo consideration
        return best_try[0] # The tempo probably changed

    def find_solution(self, d1, d2, debug=0):
        """ solve the equation : x = t1 * E(x*t2) """
        t1 = d1/d2
        t2 = d2/d1

        best_try = None
        for i in range(self.accuracy):
            if i == 0:
                values = (1,)
            else:
                values = (1 + self.dt * i, 1 - (self.dt*i))
            for v in values:
                dist_to_solution = self.dist(v, t1 * self.E(v*t2))
                best_try = self.new_best(best_try, v, dist_to_solution)
                if debug:
                    print(v, v*t2, self.E(v*t2))

                if dist_to_solution < self.eq_test:
                    return best_try[0]

        return best_try[0]


class RandomEstimator(Estimator):
    def __init__(self, accuracy=1800, limit=4 / 3, eq_test=0.0001, reg_p = 5) -> None:
        super().__init__(accuracy, limit, eq_test)
        self.poss = [2**i for i in range(-4, 5)] * reg_p # Common regular division
        self.poss += [3**i for i in range(-3, 4)]

    def E(self, _):
        return rand.choice(self.poss)


class ConsistentEstimator(Estimator):
    """ An estimator ensuring the consistency of the values it produces """
    def possible_ACD(serie, tau, accuracy=0.1):
        """ Returns all possible ACD
            NB : accuracy only allow to suppress values, could do better ?
        """
        

    def E(self, ):
        """ """

    def find_solution(self, d1, d2, debug=0):
        """ """



class TempoTracker():
    def __init__(self, estimator, tempo_init, init_time=0) -> None:
        self.estimator = estimator
        self.tempo = tempo_init
        self.last_time = None
        self.current_time = init_time

    def set_tempo(self, t):
        self.tempo = t

    def get_tempo(self):
        #self.tempo = normalize_tempo(self.tempo)
        return self.tempo

    def update_and_return_tempo(self, next_time, debug=0):
        if self.last_time is not None:
            delta_1 = self.current_time - self.last_time
            delta_2 = next_time - self.current_time

            if delta_2 > EPSILON and delta_1 > EPSILON:
                x = self.estimator.find_solution(delta_1, delta_2, debug=debug)
                if debug:
                    print(x)
                self.tempo *= x

        if next_time - self.current_time > EPSILON:
            self.last_time = self.current_time
            self.current_time = next_time

        return self.get_tempo()


def measure(spectre, delta, x=1, i=0):
    return cpp_measure(spectre, delta, x, i)

def create_pert(avg, count, pert=0.15):
    t = [avg * (1 + np.random.random() * pert) for _ in range(count)]
    return [i*2 if i < 1 else i for i in t]

class QuantiTracker():
    def __init__(self, tempo_init, init_time=0) -> None:
        self.paths = []
        self.i = None
        self.tempo_init = tempo_init
        self.tempo = None
        self.last_time = None
        self.current_time = init_time
        self.T_min = 40 # bm / s
        self.T_max = 240 # bm / s
    
    def get_tempo(self):
        if self.i is None:
            return self.tempo_init
        return 1/self.paths[self.i][0] # quarter / m or bm / s
    
        return np.max([i[1] for i in self.paths])
    
    def tempo_distance(self, t, t2):
        return abs(np.log(t / t2))
    
    def find_nearest(self, mins, const):
        i = 0
        best = self.tempo_distance(mins[0], const)
        for m in range(1, len(mins)):
            d = self.tempo_distance(mins[m], const)
            if d < best:
                best = d
                i = m

        return i, best
    
    def update_and_return_tempo(self, next_time, debug=0):
        if self.last_time is not None:
            delta_1 = self.current_time - self.last_time
            delta_2 = next_time - self.current_time

            if delta_2 > EPSILON and delta_1 > EPSILON:
                mins = find_local_minima((delta_1, delta_2), 1/self.T_max, 1/self.T_min)
                if self.i is None:
                    self.paths = [(m, 0) for m in mins]
                    self.i = self.find_nearest(mins, 1/self.tempo_init)[0]

                else:
                    for i in range(len(self.paths)):
                        if len(mins) <= 0:
                            return 10
                        j, d = self.find_nearest(mins, self.paths[i][0])
                        self.paths[i] = (mins[j], d)


        if next_time - self.current_time > EPSILON:
            self.last_time = self.current_time
            self.current_time = next_time

        return self.get_tempo()