import os
from tempo_crusher import crush_tempo
from util import EPSILON, get_matching_from_txt, fit_matching
import matplotlib.pyplot as plt
from large_score import Large
from large_et_al import QuantiTracker

init_bpm = 135
tt = QuantiTracker(init_bpm)
large = Large(init_bpm, eta_p=0.7, eta_phi=4) # 0.675, 0.65, 0.6
# (0.6, 3.14)
# (0.8, 2)

inputs = []
results = [[], [], [], [], [], [], [], [], []]

path = "../Database/nasap-dataset-main/"
folder_path = "Prokofiev/Toccata/"
folder_path = "Brahms/Six_Pieces_op_118/2/"
folder_path = "Schumann/Toccata/"
folder_path = "Liszt/Sonata/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"
folder_path = "Mozart/Piano_sonatas/11-3/"
folder_path = "Ravel/Pavane/"
folder_path = "Bach/Italian_concerto/"
folder_path = "Balakirev/Islamey/"


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
inputs = [(ind, inputs[ind]) for ind in range(len(inputs))]

import matplotlib.pylab as pylab
"""size = 35
params = {'legend.fontsize': size,
        'axes.labelsize': size,
        'axes.titlesize':size,
        'xtick.labelsize':20,
        'ytick.labelsize':20}
pylab.rcParams.update(params)
"""

already_done = []

for perfo in l[:1]:
    if perfo in already_done:
        continue
    try:
        matching = get_matching_from_txt(perfo + ".mid")
        inputs = fit_matching(matching, unit="quarter")
    except Exception as e:
        print(perfo)
        continue
    
    for ti in range(len(inputs)-1):
            beat_input, time_input = inputs[ti]
            results[0].append(time_input)

            if inputs[ti+1][1] - time_input > EPSILON:
                results[1].append(((inputs[ti+1][0] - beat_input) * 60 / (inputs[ti+1][1] - time_input)))

            results[2].append(large.update_and_return_tempo(beat_input, time_input, debug=0))
            results[3].append(tt.update_and_return_tempo(time_input, debug=1))
    
    crushed = crush_tempo([i[1] for i in inputs], results[1], results[2], mode="d")
    inputs = [(inputs[i][0], crushed[i]) for i in range(len(inputs))]
    large.set_tempo(init_bpm)

    for ti in range(len(inputs)-1):
        beat_input, time_input = inputs[ti]
        results[4].append(time_input)

        if inputs[ti+1][1] - time_input > EPSILON:
            results[5].append(((inputs[ti+1][0] - beat_input) * 60 / (inputs[ti+1][1] - time_input)))

        results[6].append(large.update_and_return_tempo(beat_input, time_input, debug=0))
        results[7].append(tt.update_and_return_tempo(time_input, debug=1))

    plt.yscale('log')
    plt.plot(results[0], results[1], '.', markersize=2, color="blue", label='Canonical tempo')
    #plt.plot(results[0], results[2], '-', markersize=2, label='Large et al. tempo')
    #plt.plot(results[0], results[3], '--', markersize=3, label='Quantified tempo')

    plt.plot(results[4], results[5], '.', markersize=2, color="red", label='Canonical tempo constant')
    #plt.plot(results[4], results[6], '-', markersize=2, label='Large et al. tempo constant')
    #plt.plot(results[4], results[7], '--', markersize=3, label='Quantified tempo constant')

    plt.xlabel('Time (second)')
    plt.ylabel('Tempo (BPM)')
    plt.legend()
    plt.show()