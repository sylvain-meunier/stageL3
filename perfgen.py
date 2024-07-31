from matplotlib import pyplot as plt
import numpy as np
from pic import load_from_txt, save
from tempo_crusher import crush_tempo, get_symbolic_shift, return_perf, generate_mono_midi_file
from models import CanonicalTempo
from large_et_al import QuantiTracker
from util import path, find_recursive, fit_matching, get_matching_from_txt, amin, get_score

save_file = "./PerfGen/" + "crushed.txt"
C_TEMPO = 120
folders = ["Mozart",
           "Glinka",
           "Prokofiev",
           "Bach"]

def generate_shifts(p=0.9):
    for f in folders:
        l = []
        find_recursive(l, path + "/" + f, rec=1)
        for perfo in l:
            try:
                matching = get_matching_from_txt(perfo + ".mid", filter_note=True)
                inputs = fit_matching(matching, unit="quarter", type="duration")
                onsets = fit_matching(matching, unit="quarter")
                if len(inputs) == 0:
                    continue
            except Exception as e:
                continue

            c = CanonicalTempo()
            can = []
            can_mono = []
            time_onsets = []
            for ti in range(len(inputs) - 1):
                ind = (onsets[ti+1][0] - onsets[ti][0], onsets[ti+1][1] - onsets[ti][1])
                if inputs[ti][1] == 0 or inputs[ti][0] == 0 or ind[0] == 0 or ind[1] == 0:
                    continue
                can.append(c.update_and_return_tempo(inputs[ti]))
                can_mono.append(c.update_and_return_tempo(ind))
                time_onsets.append(onsets[ti][1])
            
            tempo = np.median(can_mono)
            print(tempo)
            qt = QuantiTracker(tempo)
            qt_mono = QuantiTracker(tempo)
            flat = []
            flat_mono = []
            for ti in range(len(inputs) - 1):
                ind = (onsets[ti+1][0] - onsets[ti][0], onsets[ti+1][1] - onsets[ti][1])
                if inputs[ti][1] == 0 or inputs[ti][0] == 0 or ind[0] == 0 or ind[1] == 0:
                    continue
                flat.append(qt.update_and_return_tempo(inputs[ti][1]))
                flat_mono.append(qt_mono.update_and_return_tempo(inputs[ti][1]))
            crush = get_symbolic_shift(time_onsets, can_mono, flat_mono, 3, normalize=True)
            crush = [amin(p, c) if c > 0 else -amin(p, c) for c in crush]
            save(perfo, crush, path=save_file, limit=10)

def generate_perf(score, path="./PerfGen/crushed_mono.txt", constant_tempo=160):
    database = load_from_txt(path, 195)
    database = [d[1:] for d in database] # Ignore the name of the performances
    return return_perf(database, score, constant_tempo=constant_tempo)


def examples_old_castle():
    score = [1, 2.5, 3, 4, 5, 6, 7, 8.5, 9, 10, 11, 12]
    init = 51
    marche = [0, 1, 0, 3, 1, 0] + [-2, 0, -2, 1, 0, -2]
    notes = [init + m for m in marche] + [init]
    own = [1.757, 2.330, 2.534, 2.924, 3.296, 3.669, 4.080, 4.649, 4.846, 5.274, 5.650, 6.013, 6.424]
    g = generate_perf(score, path="")
    
    generate_mono_midi_file(g, notes, 160)

def example_mozart_sonata(tempo=110, sheet="Mozart/Piano_sonatas/11-3/", db="default"):
    score, notes = get_score(path + sheet)
    if db == "default":
        generated = generate_perf(score, constant_tempo=tempo)
    else:
        generated = generate_perf(score, path=db, constant_tempo=tempo)
    
    generate_mono_midi_file(generated, notes, tempo)

example_mozart_sonata(sheet="Mozart/Piano_sonatas/8-1/", tempo=160)