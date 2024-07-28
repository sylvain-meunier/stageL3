import os
import numpy as np
from util import EPSILON, get_beats_from_txt, get_matching_from_txt, fit_matching
import matplotlib.pyplot as plt
from large_score import Large, TimeKeeper, LargeKeeper
from large_et_al import QuantiTracker, Estimator, RandomEstimator, TempoTracker
from plot import biglabels

init_bpm = 40
tt = QuantiTracker(init_bpm)
tk = TimeKeeper(init_bpm, beta=0.06, alpha=0.08)
large = Large(init_bpm, eta_p=0.7, eta_phi=4) # 0.675, 0.65, 0.6
e = TempoTracker(Estimator(accuracy=250), init_bpm)
#lg = LargeKeeper(init_bpm, eta_phi=4)
# (0.6, 3.14)
# (0.8, 2)

inputs = []
results = [[], [], [], [], [], [], [], [], []]

path = "./ASAP/"
folder_path = "Prokofiev/Toccata/"
folder_path = "Brahms/Six_Pieces_op_118/2/"
folder_path = "Schumann/Toccata/"
folder_path = "Liszt/Sonata/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"
folder_path = "Mozart/Piano_sonatas/11-3/"
folder_path = "Ravel/Pavane/"
folder_path = "Bach/Italian_concerto/"
folder_path = "Balakirev/Islamey/"
folder_path = "Ravel/Miroirs/3_Une_Barque/"
folder_path = "Mozart/Piano_sonatas/11-3/"


l = []

def find_recursive(current_path, rec=False):
    listdir = os.listdir(current_path)
    midi = False
    for f in listdir:
        if ".mid" in f:
            midi = True
            f = f.split('.')
            if f[-1] != "mid" or "midi_score" in f[0]:
                continue
            if f[0] + ".match" in listdir:
                l.append(current_path + '/' + f[0])
    if rec and not midi:
        for f in listdir:
            if not "." in f:
                find_recursive(current_path + '/' + f, rec=rec)

find_recursive(path + folder_path, rec=1)
#inputs = get_beats_from_txt(l[0] + "_annotations.txt", accept_br=1)
inputs = [(ind, inputs[ind]) for ind in range(len(inputs))]

already_done = []

def normalize_tempo(a, x=1):
    return np.exp(np.log(a / x) - np.log(2) * np.floor(np.log2(a / x))) * x

#plt.rcParams['axes.facecolor'] = 'gray'
biglabels()

for perfo in l[:1]:
    if perfo in already_done:
        continue
    try:
        matching = get_matching_from_txt(perfo + ".mid")
        inputs = fit_matching(matching, unit="quarter")
        print(perfo)
    except Exception as e:
        continue

    for ti in range(len(inputs)-2):
        beat_input, time_input = inputs[ti]
        
        if time_input > 1000:
            break

        results[0].append(time_input)
        results[5].append(((inputs[ti+1][0] - beat_input) * 60 / (inputs[ti+1][1] - time_input)))

        #results[6].append(tt.update_and_return_tempo(time_input, debug=1))
        results[2].append(e.update_and_return_tempo(time_input))
        #results[2].append(tk.update_and_return_tempo(beat_input, time_input))
        #results[3].append(lg.update_and_return_tempo(beat_input, time_input, debug=1))
        #results[4].append(large.update_and_return_tempo(beat_input, time_input, debug=0))

    #plt.yscale('log')
    #plt.plot(results[0], results[5], '.', markersize=2, color="white", label='Canonical tempo')
    #plt.plot(results[0][:-1], results[2][1:], '.', markersize=3, color="black", label='Other tempo')
    #plt.plot(results[0], results[4], '-', markersize=2, label='Large et al. tempo')
    #plt.plot(results[0], results[3], '*', markersize=2, color="red", label='LargeKeeper tempo')
    #plt.plot(results[0], results[6], '--', markersize=4, color="black", label='Quantified tempo')
    tmp = results[2]
    tmp = [normalize_tempo(results[2][i]) for i in range(len(results[0]))]
    tmp2 = [normalize_tempo(results[5][i]) for i in range(len(results[0]))]
    #plt.plot(results[0], tmp2, '*', markersize=6, color="blue", label='Canonical tempo', alpha=0.5)
    #plt.plot(results[0][:-1], tmp[1:], '.', markersize=6, color="black", label='Naive estimator')
    tmp = [normalize_tempo(tmp[i+1] / tmp2[i]) for i in range(len(tmp2) - 2)]
    plt.hist(tmp, bins=100)
    #plt.plot(results[0], results[2], '--', markersize=2, color="cyan", label='TimeKeeper tempo')
    #plt.plot(results[0], results[5], '.', markersize=2, label='T∗(t)', color="yellow", alpha=0.5)
    #plt.title("Tempo curve for a performance of Islamey, Op.18, M. Balakirev with naive algorithm")
    #plt.xlabel('Time (second)')
    #plt.ylabel('Normalized tempo')
    #plt.legend()
    plt.show()
