import numpy as np
import partitura as pt
from symusic import Score

def crush_tempo(performance, canonical_tempo, flattened_tempo=None, constant_tempo=None, mode="default", p=0.5, k=3):
    """ Returns a performance with controlled tempo variation around @constant_tempo
        performance : a list or array of input events
        canonical_tempo : a list or array of corresponding canonical tempo (hence with exactly one element less than the performance)
        flattened_tempo : same as @canonical_tempo, but with a certain flattened curve, can be None
        constant_tempo : the approximate tempo of the generated performance
        mode : either
            . 'd' for default : multiply the all the shift by @p <= 1
            . 'c' for cut : only allows shifts representing less than @p <= 1 of the note theorical duration
            . 'h' for hard : normalizes all the shifts, and then multiply them all by @p
        p : parameter of the specified mode. Usually, 0 means a total plain midi result, and 1 the original performance
        k : if flattened_tempo is None, length of the sliding frame to compute the median from
    """
    assert (constant_tempo is not None and flattened_tempo is None)
    if constant_tempo is None:
        constant_tempo = np.median(flattened_tempo)
    crush = performance.copy()

    symbolic_shifts = []
    for n in range(len(performance) - 1):
        canon = canonical_tempo[n]
        if flattened_tempo is None:
            flat = np.median(canonical_tempo[n-k:n+k])
        else:
            flat = flattened_tempo[n]
        duration = performance[n+1] - performance[n]

        # in symbolic unit
        symbolic_shifts.append(duration * (flat - canon))

    symbolic_shifts = np.array(symbolic_shifts)

    if mode == "d" or mode == "default" :
        symbolic_shifts *= p
    elif mode == "c" or mode == "cut" :
        for n in range(len(performance) - 1):
            duration = performance[n+1] - performance[n]
            tmp = symbolic_shifts[n] / (duration * canonical_tempo[n])
            symbolic_shifts[n] = min(p, tmp) * (duration * canonical_tempo[n])
    else:
        max_shift = np.max(symbolic_shifts)
        symbolic_shifts *= p / max_shift

    for n in range(len(performance) - 1):
        canon = canonical_tempo[n]

        if flattened_tempo is None:
            flat = np.median(canonical_tempo[n-k:n+k])
        else:
            flat = flattened_tempo[n]

        duration = performance[n+1] - performance[n]
        
        new_duration = canon * duration / constant_tempo
        crush[n+1] = crush[n] + new_duration + symbolic_shifts[n] / constant_tempo
    return crush

def save_midi(crushed_tempo, inital_path, dest):
    """
        Save a generated performance to MIDI format
    @crushed_tempo :
    @dest : the path of the target MIDI file to create
    """
    # convert note array to midi and save result
    pt.save_performance_midi()
