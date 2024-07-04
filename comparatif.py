import os
import numpy as np
from util import EPSILON, get_beats_from_txt, get_matching_from_txt, fit_matching
from random import random
import matplotlib.pyplot as plt
from large_et_al import *

def rand(a):
    b = random() * a
    if b > a/2:
        return b  - a
    return b

hands = 0
init_bpm = 125
t = Oscillateur2(tempo_init=init_bpm, eta_s=1, eta_p=0.17, eta_phi=2)
t2 = Oscillateur2(tempo_init=init_bpm, eta_s=1, eta_p=0.17, eta_phi=2)
tempo = TimeKeeper(tempo_init=init_bpm, alpha=0.5, beta=0.3)
tm = Oscillateur(tempo_init=init_bpm, eta_s=0.7, eta_p=0.9)
double_osc = TempoModel(ratio=4, alpha=0.8, tempo_init=init_bpm)
bk = BeatKeeper(tempo_init=init_bpm, eta_phi=0.81, min_kappa=1)
#tt = TempoTracker(Estimator(), tempo_init=init_bpm)
tt = QuantiTracker(init_bpm)
lg = LargeKeeper(tempo_init=init_bpm, eta_s=0.7, eta_p=0.9)

inputs = []
results = ([], [], [], [], [], [], [], [], [])
def add_input(inputs, results, bpm, time, delta=0, last_time = None, perturb=0.50):
        bpm -= delta
        if len(inputs) == 0:
            last_time = 0
        elif last_time is None:
            last_time = inputs[-1]
        results[-1].append(bpm)
        results[-1].append(bpm)
        results[-2].append(last_time+0.001)
        results[-2].append(last_time + time)
        return inputs + [i + rand(perturb * 60 / bpm) for i in np.linspace(last_time, last_time + time, int(time / 60 * bpm + 1))]


inputs = add_input(inputs, results, 120, 10)
inputs = add_input(inputs, results, 160, 100)
inputs = add_input(inputs, results, 120, 100)
inputs = add_input(inputs, results, 110, 100)
inputs = add_input(inputs, results, 120, 200)
inputs = add_input(inputs, results, 130, 200)
inputs = add_input(inputs, results, 150, 100)
bpm=140
last_time = inputs[-1]
time = 100
tmp = np.linspace(last_time, last_time + time, int(time / 60 * bpm))
inputs += [tmp[i] for i in range(len(tmp)) if i % 3 != 0]

#inputs = add_input(inputs, results, 80, 500)
"""inputs = add_input(inputs, results, 55, 100)
inputs = add_input(inputs, results, 40, 100)
inputs = add_input(inputs, results, 120, 1000)
inputs = add_input(inputs, results, 110, 100)
inputs = add_input(inputs, results, 120, 200)
inputs = add_input(inputs, results, 130, 200)
inputs = add_input(inputs, results, 120, 1000)"""

def fit(a, maxi=240, mini=20):
     return max(mini, min(maxi, a))

#fit = normalize_tempo

path = "../Database/nasap-dataset-main/"
folder_path = "Prokofiev/Toccata/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"
folder_path = "Bach/Italian_concerto/"
folder_path = "Brahms/Six_Pieces_op_118/2/"
folder_path = "Liszt/Sonata/"
folder_path = "Mozart/Piano_sonatas/11-3/"
folder_path = "Balakirev/Islamey/"
folder_path = "Schumann/Toccata/"

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

#plt.yscale("log")
ratio = []
nb_piece = 0

already_done = []

for perfo in l[:1]:
    if perfo in already_done:
        continue
    try:
        matching = get_matching_from_txt(perfo + ".mid")
        inputs = fit_matching(matching, unit="quarter")
        print(perfo)
        nb_piece += 1
    except Exception as e:
        continue

    for ti in range(len(inputs)-1):
            beat_input, time_input = inputs[ti]
            results[0].append(time_input)
            #results[1].append(t.update_and_return_tempo(time_input, debug=0, iter=2))
            #results[2].append(t2.update_and_return_tempo(time_input, debug=0, kappa=False))
            #results[3].append(normalize_tempo(bk.update_and_return_tempo(time_input, debug=0)))
            #results[3].append(tempo.update_and_return_tempo(time_input, debug=0))
            #results[3].append(double_osc.update_and_return_tempo(beat_input, time_input, debug=0, iter=1))
            #results[4].append(tm.update_and_return_tempo(beat_input, time_input, debug=0, iter=1))
            if inputs[ti+1][1] - time_input > EPSILON:
                results[5].append(((inputs[ti+1][0] - beat_input) * 60 / (inputs[ti+1][1] - time_input)))
            else:
                results[5].append(init_bpm)
            results[6].append(tt.update_and_return_tempo(time_input, debug=0))
            #results[1].append(lg.update_and_return_tempo(beat_input, time_input))

    #tmp = [normalize_tempo(i, min=1, max=2) for i in np.array(results[6][1:]) / np.array(results[5][:-1])]
    #naive = results[5][:-1]
    #estim = results[6][1:]
    #tmp = [normalize_tempo(estim[i] / estim[i+1] * naive[i+1] / naive[i], min=1, max=2) for i in range(len(naive) - 1)]
    #plt.title(str(measure(tmp, 0.15)))
    #plt.hist(tmp, bins=100)
    #plt.show()

    '''
    fig, ax1 = plt.subplots()
    plt.yscale("log")
    ax1.plot(results[0], results[5], '.', markersize=2, label='Error')
    plt.yscale("log")
    ax1.twinx().plot(results[0], results[6], '.', markersize=2, label='score')
    plt.show()
    '''
    plt.yscale("log")
    plt.plot(results[0], results[6], '.', markersize=2, label='Error')
    plt.plot(results[0], results[5], '.', markersize=2, label='Score')
    plt.show()

    #plt.plot(results[0], results[3], '-' , markersize=2, label="Timekeeper")
    #plt.plot(results[0], results[4], '-' , markersize=2, color="yellow", label="2010 Oscillator")
    #plt.plot(results[0], results[3], '-' , markersize=2, label="Beatkeeper")
    #plt.plot(results[0], results[3], '-', markersize=2, label="Double Oscillator")
    # plt.plot(results[0][:-1], results[6][1:], '.', markersize=5, label="TempoTracker", alpha=0.5)
    #plt.scatter([0] * len(ratio), ratio, alpha=0.01)
    #plt.plot(results[0], results[2], '-', color="blue" , markersize=2, label="Naive oscillator", alpha=0.5)
    #plt.plot(results[0], results[1], '*', color="black" , markersize=2, label="Oscillator (kappa corrected)", alpha=0.5)
    #plt.plot(results[-2], results[-1], label="Constant forced BPM input")
    #plt.title("Tempo curve for fixed entry with ± 10% perturbation")

plt.title("Tempo curve for a performance of " + folder_path[:-1])
plt.ylabel("Tempo (bpm)")
plt.xlabel("Time (second)")
plt.legend()
plt.show()