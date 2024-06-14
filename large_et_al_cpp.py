# Adapted from Large & Jones (1999) : https://research.ebsco.com/c/glmwyg/viewer/pdf/24oxihnocr?route=details

import numpy as np
from kappa import kappa_list, kappa_table

class T_Tempo():
    def __init__(self) -> None:
        self.kappa = 2.                     # Expectancy parameter for Mises-Von distribution (or variance!)
        self.s_kappa = 0.94                 # Maximum likelihood value approximation of kappa
        self.eta_s = 0.9                    # Propagation parameter for kappa max. likelihood approx.
        self.rt_tempo = 1.                  # Realtime estimated tempo (second / beat)
        self.last_instantaneous_tempo = 1.
        self.tempo_correction = 0.          # Tempo correction value at each step
        self.min_kappa = 1.                 # Minimum KAPPA value not to bypass (to manually limit tempo variation)
        self.small_variation = 0

    def wrap_phi(self, time_event):
        """ Return the phase corresponding to the time_event, according to the current period (ie estimated tempo) """
        while (time_event < 0):
            time_event += self.rt_tempo
        while (time_event > self.rt_tempo):
            time_event -= self.rt_tempo
        ratio = time_event / self.rt_tempo
        if ratio > 0.5:
            return ratio - 1
        return ratio # phi mod[-0.5, 0.5] 1

    def get_tempo(self):
        return 60 / self.rt_tempo # beat

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
        self.last_instantaneous_tempo = new_tempo
        self.small_variation = 0

    def entrain(self, phi, kappa):
        """ Entrainement Function based on Mises-Von first derivative distribution """
        return (1.0/(2.0*np.pi*np.exp(kappa))) * np.exp(kappa * np.cos(2.0*np.pi*phi))*np.sin(2.0*np.pi*phi)
    
    def tempo0sc(self, passed_phi, passed_beat, score_tempo, x_elapsedrealtime, verbosity=1):
        """ Mono-tonic tempo update oscillator based on Large & Jones.
        @passed_phi        passed phase in the score
        @passed_beat       passed beat time in the score
        @score_tempo       Tempo in the score
        @x_elapsedrealtime       Passed absolute time (seconds)
        @verbosity        verbosity flag for debugging
        @Result : update internal tempo
        """
        assert(self.rt_tempo >= 0.)
        assert(passed_beat > 0.)
        assert(score_tempo > 0.)
        assert(x_elapsedrealtime >= 0.)

        new_rt_tempo = -666.666

        # Calculate realtime phase
        if (self.rt_tempo == 0.0):
            self.rt_tempo = score_tempo

        rt_beat = x_elapsedrealtime / self.rt_tempo - self.tempo_correction
        rt_phi = self.wrap_phi(rt_beat)
        phi_diff = self.wrap_phi(rt_beat - passed_beat)

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
        self.small_variation = 0

        assert(new_rt_tempo >= 0)

        if (verbosity > 0):
            print("RT phi", rt_phi, "passed phase", passed_phi, "delta", phi_diff, "tempo correction", self.tempo_correction, "TEMPO=", self.rt_tempo, "(" + str(self.get_tempo()) + "BPM)", "Kappa=", self.kappa)

        self.tempo_update(new_rt_tempo)


class T_Tempo_Var(T_Tempo):
    def init_var(self, temp_init = 60., f = 1.): # name_mangling on init method, only way to translate the equivalent c++ code
        self.init()     # method of ancestor T_Tempo
        self.freq = f
        self.freq_init = f
        self.tempo_init = temp_init
        self.last_time = -1.
        self.rt_tempo  = 60. / self.tempo_init
        self.freq = self.freq_init
        self.last_position = -1.
        self.ind = 0

    def TempoUpdate(self, tempo_spb):
        assert (tempo_spb > 0)
        self.rt_tempo = tempo_spb


    def set_tempo(self, beats):
        self.rt_tempo = 60. / beats

    def tempo0sc_var(self, now): # name_mangling on init method, only way to translate the equivalent c++ code
        if self.last_time == -1.:
            self.last_position = 0
            self.ind = 1
        else:
            self.last_position += self.freq
            x_elapsedrealtime = now - self.last_time
            if (x_elapsedrealtime > 0):
                # method of ancestor T_Tempo
                self.tempo0sc(self.wrap_phi(self.freq), self.freq, self.rt_tempo, x_elapsedrealtime)
            self.ind = np.floor(self.last_position / self.freq) + 1
        self.last_time = now
        return self.get_tempo()
