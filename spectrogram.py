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

init_bpm = 100
tt = QuantiTracker(init_bpm)

inputs = []
results = ([], [], [], [], [], [], [], [], [])

path = "../Database/nasap-dataset-main/"
folder_path = "Prokofiev/Toccata/"
folder_path = "Bach/Italian_concerto/"
folder_path = "Brahms/Six_Pieces_op_118/2/"
folder_path = "Liszt/Sonata/"
folder_path = "Schumann/Toccata/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"
folder_path = "Balakirev/Islamey/"
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

ratio = []
nb_piece = 0
already_done = []

for perfo in l[1:2]:
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

            if inputs[ti+1][1] - time_input > EPSILON:
                results[5].append(((inputs[ti+1][0] - beat_input) * 60 / (inputs[ti+1][1] - time_input)))
            else:
                results[5].append(init_bpm)
            tt.update_and_return_tempo(time_input)
            if ti % 50 == 0:
                for t, e in tt.get_possible_tempi():
                    plt.scatter([time_input], [t], alpha=1/120, color="black") # e / 50
            print(ti, len(tt.get_possible_tempi()))

    #plt.plot(results[0], results[6], '.', markersize=2, label='Error')
    plt.plot(results[0], results[5], '.', markersize=2, label='Score')
    plt.show()