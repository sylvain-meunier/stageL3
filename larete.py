import os
import numpy as np
from util import EPSILON, get_beats_from_txt, get_matching_from_txt, fit_matching, path, find_recursive
import matplotlib.pyplot as plt
from large_score import Large, TimeKeeper, LargeKeeper
from large_et_al import AbsoluteEstimator, DurationTempoTracker, QuantiTracker, Estimator, RandomEstimator, SmartRandomEstimator, TempoTracker, measure, normalize_tempo
from plot import biglabels
from pic import load_done, save, Timer, txt_to_pickle

init_bpm = 185
tt = QuantiTracker(init_bpm)
tk = TimeKeeper(init_bpm, beta=0.06, alpha=0.08)
large = Large(init_bpm, eta_p=0.7, eta_phi=4) # 0.675, 0.65, 0.6
e = TempoTracker(Estimator(accuracy=250), init_bpm)
#lg = LargeKeeper(init_bpm, eta_phi=4)
# (0.6, 3.14)
# (0.8, 2)

save_file = "poly_measure.txt"

folder_path = "Brahms/Six_Pieces_op_118/2/"
folder_path = "Schumann/Toccata/"
folder_path = "Liszt/Sonata/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"
folder_path = "Ravel/Pavane/"
folder_path = "Bach/Italian_concerto/"
folder_path = "Ravel/Pavane/"
folder_path = "Balakirev/Islamey/"
folder_path = "Mozart/Fantasie_475/"
folder_path = "Prokofiev/Toccata/"
folder_path = "Ravel/Pavane/"
folder_path = "Mozart/Piano_sonatas/11-3/"

l = []
find_recursive(l, path, rec=1)
already_done = load_done(save_file)
timer = Timer(1017, current=len(already_done))

#plt.rcParams['axes.facecolor'] = 'gray'
biglabels()

for perfo in l:
    if perfo in already_done:
        continue
    try:
        matching = get_matching_from_txt(perfo + ".mid", filter_note=False)
        inputs = fit_matching(matching, unit="beat", type="duration")
        onsets = fit_matching(matching, unit="beat")
        print(perfo)
        if len(inputs) == 0:
            continue
        timer.update()
    except Exception as e:
        continue

    e = DurationTempoTracker(Estimator(accuracy=250), init_bpm)
    results = [[], [], [], [], [], [], [], [], []]
    for ti in range(len(inputs)):
        beat_input, time_input = inputs[ti]
        if time_input == 0:
            continue
        time_onset = onsets[ti][1]

        results[0].append(time_onset)
        #results[5].append(((inputs[ti+1][0] - beat_input) * 60 / (inputs[ti+1][1] - time_input)))
        results[5].append(beat_input / time_input * 60)

        #results[6].append(tt.update_and_return_tempo(time_input, debug=1))
        results[2].append(e.update_and_return_tempo(time_input))
        #results[2].append(tk.update_and_return_tempo(beat_input, time_input))
        #results[3].append(lg.update_and_return_tempo(beat_input, time_input, debug=1))
        #results[4].append(large.update_and_return_tempo(beat_input, time_input, debug=0))

    #plt.yscale('log')
    #plt.plot(results[0], results[5], '.', markersize=2, color="blue", label='Canonical tempo')
    #plt.plot(results[0][:-1], results[2][1:], '.', markersize=3, color="black", label='Other tempo')
    #plt.plot(results[0], results[4], '-', markersize=2, label='Large et al. tempo')
    #plt.plot(results[0], results[3], '*', markersize=2, color="red", label='LargeKeeper tempo')
    #plt.plot(results[0], results[6], '--', markersize=4, color="black", label='Quantified tempo')
    #tmp = results[2]
    #tmp2 = results[5]
    tmp = [normalize_tempo(results[2][i]) for i in range(len(results[0]))]
    tmp2 = [normalize_tempo(results[5][i]) for i in range(len(results[0]))]

    #plt.plot(results[0], tmp2, '*', markersize=6, color="blue", label='Canonical tempo', alpha=0.5)
    #plt.plot(results[0], tmp, '.', markersize=6, color="black", label='Naive estimator')
    tmp3 = [normalize_tempo(tmp[i] / tmp2[i]) for i in range(len(tmp2))]
    tmp3 = [i for i in tmp3 if i > 0] # Don't consider grace notes

    save(perfo, tmp3, path=save_file)

    #plt.plot(results[0], results[2], '--', markersize=2, color="cyan", label='TimeKeeper tempo')
    #plt.plot(results[0], results[5], '.', markersize=2, label='T∗(t)', color="yellow", alpha=0.5)
    #plt.title("Tempo curve for a performance of Islamey, Op.18, M. Balakirev with naive algorithm")
    #plt.xlabel('Time (second)')
    #plt.ylabel('Normalized tempo')
    #plt.legend()
    #plt.show()

txt_to_pickle(path=save_file)