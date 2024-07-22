import numpy as np
import partitura as pt

def crush_tempo(performance, canonical_tempo, flattened_tempo, constant_tempo=None, mode="default", p=0.5):
    """ Returns a performance with controlled tempo variation around @constant_tempo """
    if constant_tempo is None:
        constant_tempo = np.median(flattened_tempo)
    crush = performance.copy()

    symbolic_shifts = []
    for n in range(len(performance) - 1):
        canon = canonical_tempo[n]
        flat = flattened_tempo[n]
        duration = performance[n+1] - performance[n]

        # in symbolic unit
        symbolic_shifts.append(duration * (flat - canon))

    symbolic_shifts = np.array(symbolic_shifts)

    if mode == "d" or mode == "default" :
        symbolic_shifts *= p
    elif mode == "c" or mode == "cut" :
        symbolic_shifts = min(p, symbolic_shifts)
    else:
        max_shift = np.max(symbolic_shifts)
        symbolic_shifts *= p / max_shift

    for n in range(len(performance) - 1):
        canon = canonical_tempo[n]
        flat = flattened_tempo[n]
        duration = performance[n+1] - performance[n]
        
        new_duration = canon * duration / constant_tempo
        crush[n+1] = crush[n] + new_duration + symbolic_shifts[n] / constant_tempo
    return crush

def save_midi(crushed_tempo):
    # convert note array to midi and save result + listening check
    pt.save_performance_midi()
