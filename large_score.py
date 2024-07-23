from kappa import kappa_list, kappa_table
import numpy as np
from util import EPSILON

RAD = 2 * np.pi

def minabs(a, b):
    if abs(a) < abs(b):
        return a
    return b

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
        self.period = 60 / t

    def period_to_tempo(self, period):
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

    def update_and_return_tempo(self, current_beat, current_time, debug=0):
        k = int(self.phase - current_beat)
        dphi = -minabs(k + current_beat - self.phase, k + 1 + current_beat - self.phase)
        self.phi = dphi
        self.dt = current_time - self.last_time
        self.update_parameters(current_time, dphi, debug=debug)
        return self.get_tempo()


class LargeKeeper(Large):
    def get_tempo(self):
        p = self.period
        self.prev = self.period_to_tempo(p)
        #p = self.period_to_tempo(p)
        curr = p / (1 - p * self.eta_phi * self.F(self.phase, self.kappa) / (self.dt))
        curr = self.period_to_tempo(curr)
        
        self.prev = curr
        return curr


class TimeKeeper():
    def __init__(self, tempo_init=120, a0=0, alpha=0.05, beta=0.05, last_time=0) -> None:
        self.alpha = alpha                  #
        self.beta = beta                    #
        self.tau = 60 / tempo_init          # s (/ beat)
        self.asynchrony = a0                # s
        self.last_time = last_time
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

    def update_and_return_tempo(self, current_beat, current_time, debug=0):
        k = int((self.asynchrony - current_beat) / self.tau)
        asyn = -minabs(-self.asynchrony + current_beat + k*self.tau, (k+1)*self.tau - (self.asynchrony - current_beat))
        self.update_parameters(current_time, asyn, debug=debug)
        return self.get_tempo()
