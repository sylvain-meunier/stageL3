import numpy as np
import partitura as pt
from symusic import Score
from random import choice, shuffle

def get_symbolic_shift(performance, canonical_tempo, flattened_tempo, k, normalize=0):
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

        if normalize: # No unit
            symbolic_shifts[-1] /= canon * duration

    return np.array(symbolic_shifts)

def next_symbolic_shift(sym_s, db, lim=0.01):
    if len(db) == 0:
        return sym_s

    while True :
        d = choice(db)
        for i in range(len(d)-1):
            s = d[i]
            if abs(s - sym_s) < lim:
                return d[i+1]


def return_perf(database, score, constant_tempo = 120, c=0.2):
    def cut(shift):
        if abs(shift) <= c:
            return shift
        if shift < 0:
            return -c
        return c

    constant_tempo /= 60 # Conversion to beat per second
    shuffle(database)
    crush = [0] * len(score)
    if len(database) > 0:
        symbolic_shift = choice(database)[0] # Initial symbolic shift
    else:
        symbolic_shift = 0
    for n in range(len(score) - 1):
        dur = score[n+1] - score[n]
        new_duration = dur / constant_tempo
        crush[n+1] = crush[n] + new_duration + cut(symbolic_shift) * dur / constant_tempo
        symbolic_shift = next_symbolic_shift(symbolic_shift, database)
    return crush

def crush_tempo(performance, canonical_tempo, flattened_tempo=None, constant_tempo=None, mode="default", p=0.5, k=3):
    """ Returns a performance with controlled tempo variation around @constant_tempo
        performance : a list or array of input events
        canonical_tempo : a list or array of corresponding canonical tempo (hence with exactly one element less than the performance)
        flattened_tempo : same as @canonical_tempo, but with a certain flattened curve, can be None
        constant_tempo : the approximate tempo of the generated performance, expressed in beat per minute
        mode : either
            . 'd' for default : multiply the all the shift by @p <= 1
            . 'c' for cut : only allows shifts representing less than @p <= 1 of the note theorical duration
            . 'h' for hard : normalizes all the shifts, and then multiply them all by @p
        p : parameter of the specified mode. Usually, 0 means a total plain midi result, and 1 the original performance
        k : if flattened_tempo is None, length of the sliding frame to compute the median from
    """
    assert (canonical_tempo is not None)
    if constant_tempo is None:
        constant_tempo = np.median(canonical_tempo)
        if flattened_tempo is not None:
            constant_tempo = np.median(flattened_tempo)
    crush = performance.copy()
    constant_tempo /= 60 # Conversion to beat per second

    symbolic_shifts = get_symbolic_shift(performance, canonical_tempo, flattened_tempo, k)

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
        duration = performance[n+1] - performance[n] 
        new_duration = canon * duration / constant_tempo

        crush[n+1] = crush[n] + new_duration + symbolic_shifts[n] / constant_tempo
    return crush

from mido import Message, MetaMessage, MidiFile, MidiTrack, bpm2tempo, second2tick

def generate_mono_midi_file(performance, notes, tempo, key_signature="Dm", ts=(6, 8), save_file="gen_perf.mid", save_folder = "./PerfGen/", delay=0.5, velocity=80):
    mid = MidiFile()
    track = MidiTrack()
    mid.tracks.append(track)

    tempo = bpm2tempo(tempo)

    track.append(MetaMessage('key_signature', key=key_signature))
    track.append(MetaMessage('set_tempo', tempo=tempo))
    track.append(MetaMessage('time_signature', numerator=ts[0], denominator=ts[1]))

    track.append(Message('program_change', program=12, time=second2tick(delay, mid.ticks_per_beat, tempo)))

    for i in range(len(performance) - 1):
        note = notes[i]
        duration = performance[i+1] - performance[i]
        track.append(Message('note_on', channel=1, note=note, velocity=velocity, time=0))
        track.append(Message('note_off', channel=1, note=note, velocity=velocity, time=second2tick(duration, mid.ticks_per_beat, tempo)))

    track.append(MetaMessage('end_of_track'))

    mid.save(save_folder + save_file)