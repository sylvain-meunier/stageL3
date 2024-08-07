import numpy as np
from plot import biglabels
import matplotlib.pyplot as plt
from models import Large, QuantiTracker, CanonicalTempo
from util import EPSILON, get_beats_from_txt, get_matching_from_txt, fit_matching, find_recursive, path

init_bpm = 100
can = CanonicalTempo(init_bpm)
tt = QuantiTracker(init_bpm)
large = Large(init_bpm, eta_p=0.7, eta_phi=4) # 0.675, 0.65, 0.6

inputs = []
results = [[], [], [], [], [], [], [], [], []]

folder_path = "Bach/Italian_concerto/"

l = []
find_recursive(l, path + folder_path, rec=1)
fig, ax = biglabels()

ratio = []
nb_piece = 0
already_done = []

for perfo in l:
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
        input = (inputs[ti+1][0] - beat_input, inputs[ti+1][1] - time_input)
        results[5].append(can.update_and_return_tempo(input))
        results[4].append(large.update_and_return_tempo(beat_input, time_input))

    plt.yscale('log')
    fig.canvas.manager.full_screen_toggle()
    plt.plot(results[0], results[5], '*', markersize=7, color="blue", alpha=0.5, label="Canonical tempo")
    plt.plot(results[0], results[4], '-', markersize=3, color="red", label="Large et al. tempo")
    for ti in range(len(inputs)-1):
        beat_input, time_input = inputs[ti]
        tt.update_and_return_tempo(time_input)
        if ti % 20 == 0:
            for t, e in tt.get_possible_tempi():
                if t <= 100:
                    plt.scatter([time_input], [t], color="black", s=50)
        print(ti, len(tt.mins))
    plt.xlabel('Time (second)')
    plt.ylabel('Tempo (BPM)')
    #plt.legend()
    plt.show()