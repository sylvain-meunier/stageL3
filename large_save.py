import scipy
import numpy as np
import scipy.special
from kappa import kappa_list, kappa_table

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


# 2010 Oscillator
class Oscillateur():
    def __init__(self, tempo_init=None, phase=0, min_kappa=1, last_time=0, phase_coupling=1, period_coupling=1, eta_s = 0.9) -> None:
        if tempo_init is None:
            tempo_init = 120
        self.period = 60 / tempo_init           # second / beat (default to 120 bpm)
        self.phase = phase                      # in the range [-0.5, 0.5]
        self.s_kappa = 0.94
        self.kappa = 2.                         # Expectancy parameter for Mises-Von distribution (or variance!)
        self.eta_s = eta_s                      # Propagation parameter for kappa max. likelihood approx. in [0, 1]
        self.last_time = last_time              # Last known event (s)
        self.phase_coupling = phase_coupling
        self.period_coupling = period_coupling
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

    def update_parameters(self, n, score_phase, current_time, debug=0):
        """ Update internal parameters, according to the model equations """
        phi = (self.phase - score_phase)
        p = self.period  / n # Update the period according to the expected next IOI (double, etc...)

        if ((current_time - self.last_time) >= p):
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

        self.phase += (current_time - self.last_time) / p + self.phase_coupling * self.entrain(phi, self.kappa)
        self.phase = self.normalize_phase(self.phase)

        self.period *= 1 + self.period_coupling * self.entrain(phi, self.kappa)
        self.last_time = current_time

        if debug:
            print(int(self.get_tempo()), "BPM ; Kappa :", self.kappa, " ; Phase :", str(self.phase)[:5], "(" + str(self.phase - phi)[:5] + ")")

    def find_minimal_integer_ratio(self, ratio, precision=0.0001):
        """ Returns the lesser integer n such that n*ratio is an integer  """
        for i in range(1, 8*3+1):
            if abs(i * ratio - int(i*ratio)) < precision:
                return i
        return 1
    
    def fit_to_accuracy(self, acc, value):
        return int(value * acc) / acc
    
    def average(self, v1, v2, n):
        """ Returns a certain average of values v1 and v2, according to n and advantaging v1 """
        return np.exp((np.log(v1) * (n-1) + np.log(v2)) / n)

    def update_and_return_tempo(self, score_beat, current_time, accuracy=1000, debug=0, iter=1):
        current_time += self.error
        delta = current_time - self.last_time
        n = self.find_minimal_integer_ratio(score_beat - np.floor(score_beat))
        for _ in range(iter):
            if delta > EPSILON:
                prev_p = self.period
                # In this case, since the unit of score_beat is beat, the theorical period is exactly 1 beat. Thus, this formula gives the theoric (or expected) phase
                score_phase = (score_beat / 1)
                score_phase = score_phase - np.floor(score_phase) # Mod 1
                score_phase = self.fit_to_accuracy(accuracy, score_phase)
                self.update_parameters(n, score_phase, current_time, debug=debug)
                #self.period = self.average(prev_p, self.period, n)
                current_time += delta
        self.error += delta * (iter-1)
        return self.get_tempo()


class TempoModel():
    def __init__(self, ratio, alpha, tempo_init, min_kappa=1, eta_s=0.9, eta_phi=2, eta_p=0.4) -> None:
        self.alpha = alpha
        self.ratio = ratio
        self.oscillators = [Oscillateur2(tempo_init=tempo_init * ratio, min_kappa=min_kappa, eta_s=eta_s, eta_phi=eta_phi, eta_p=eta_p),
                            Oscillateur2(tempo_init=tempo_init, min_kappa=min_kappa, eta_s=eta_s, eta_phi=eta_phi, eta_p=eta_p)
                            ]

    def update_and_return_tempo(self, current_time, debug=0):
        o1 = self.oscillators[0]
        o2 = self.oscillators[1]
        phi12 = -self.alpha * (o1.phase - o2.phase * self.ratio)    # Coupling phase strenght from 1 to 2
        phi21 = -self.alpha * (o2.phase - o1.phase / self.ratio)    # Coupling phase strenght from 2 to 1
        p12 = -self.alpha * (o2.period - o1.period * self.ratio)
        p21 = -self.alpha * (o2.period - o1.period / self.ratio)
        self.oscillators[0].update_parameters(current_time, phase_coupling=0, period_coupling=p21)
        self.oscillators[1].update_parameters(current_time, phase_coupling=0, period_coupling=p12)
        return self.oscillators[0].get_tempo()


# 14/06 : naive Estimator with normalization needed
class Estimator():
    def __init__(self, accuracy=100, limit=2, eq_test=0.00001) -> None:
        """ naive version : no memory """
        self.accuracy = accuracy
        self.limit = limit
        self.dt = (limit - 1) / accuracy
        self.eq_test = eq_test

    def new_best(self, current_best, new_value, new_dist):
        if current_best is None or (current_best[1] > self.eq_test and new_dist < current_best[1]):
            return (new_value, new_dist)
        return current_best

    def E(self, a):
        """ Returns an estimation as described in the equation """
        assert(a > 0)
        best_try = (1, abs(a - 1))

        # Test if a is a power of 2
        log2 = np.floor(np.log2(a))
        for t in (log2, log2+1):
            if -16 <= t <= 16:
                best_try = self.new_best(best_try, 2**t, abs(a - 2**t))

        # Test if
        n_a = 3*a
        # Test if n_a is a power of 2 (triolet, but not only)
        log2 = np.floor(np.log2(n_a))
        for t in (log2, log2+1):
            if -16 <= t <= 16 and 0:
                best_try = self.new_best(best_try, 2**t / 3, abs(a - 2**t / 3))

        if abs(np.log(best_try[0] / a)) < self.eq_test:
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
                values = (1 + self.dt * i, 1 / (1 + self.dt*i))
            for v in values:
                dist_to_solution = abs(v - t1 * self.E(v*t2))
                best_try = self.new_best(best_try, v, dist_to_solution)
                if debug:
                    print(v, v*t2, self.E(v*t2))

                if dist_to_solution < self.eq_test:
                    return best_try[0]

        return best_try[0]


class TempoTracker():
    def __init__(self, tempo_init, init_time=0) -> None:
        self.estimator = Estimator()
        self.tempo = tempo_init
        self.last_time = None
        self.current_time = init_time

    def get_tempo(self):
        self.tempo = normalize_tempo(self.tempo)
        return self.tempo

    def update_and_return_tempo(self, next_time, debug=0):
        if self.last_time is not None:
            delta_1 = self.current_time - self.last_time
            delta_2 = next_time - self.current_time

            if delta_2 > EPSILON and delta_1 > EPSILON:
                x = self.estimator.find_solution(delta_1, delta_2, debug=0)
                self.tempo *= x

        if next_time - self.current_time > EPSILON:
            self.last_time = self.current_time
            self.current_time = next_time

        return self.get_tempo()
