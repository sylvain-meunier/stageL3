from kappa import kappa_list, kappa_table
import numpy as np
from util import EPSILON

RAD = 2 * np.pi

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
        if current_beat > self.phase:
            dphi = min(current_beat - self.phase, self.phase - (current_beat - 1))
        else:
            dphi = min(self.phase - current_beat, current_beat - (self.phase - 1))
        dphi = current_beat - self.phase
        self.update_parameters(current_time, dphi, debug=debug)
        return self.get_tempo()
