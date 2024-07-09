import os
import numpy as np
from util import EPSILON, get_matching_from_txt, fit_matching
from random import random
import matplotlib.pyplot as plt
from large_et_al import *
from PIL import Image

init_bpm = 100
min_error = EPSILON / 10000 # contrast parameter
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

def path_to_name(path_):
    return path_[len(path):].replace('/', '_').replace('.', '')

folder_save = "./Figures/Spectrogram/"

l = []

radius = 2
circle = []
for i in range(-radius, radius+1):
    for j in range(-radius, radius+1):
        if i**2 + j**2 <= radius**2:
            circle.append((i, j))

def plot_point(tab, x, y, color, update):
    for i, j in circle:
        if 0 <= (x + i) < len(tab) and 0 <= (y + j) < len(tab[0]):
            update(tab, x+i, y+j, color)

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

def update_amount(tab, x, y, color):
    tab[x, y] = [min(c, 255) for c in color]

for perfo in l:
    matching = get_matching_from_txt(perfo + ".mid")
    inputs = fit_matching(matching, unit="quarter")

    tatum = 1 / 60 # quarter
    maxinput = inputs[-1][0] # quarter
    image_width = int(maxinput / tatum) + 1
    #image_width = len(inputs)-1
    interval = tt.get_interval()
    accuracy = 0.25 # quarter per minute
    image_height = int(abs(interval[0] - interval[1]) / accuracy) + 1
    img = np.zeros((image_width, image_height, 3), dtype=np.uint8)
    img2 = np.zeros((image_width, image_height, 4), dtype=np.uint8)

    x_ind = 0

    for ti in range(len(inputs)-1):
            beat_input, time_input = inputs[ti]
            if inputs[ti+1][1] - time_input > EPSILON:
                results[5].append(((inputs[ti+1][0] - beat_input) * 60 / (inputs[ti+1][1] - time_input)))

            x_ind = int((beat_input / maxinput) * image_width)

            tt.update_and_return_tempo(time_input)
            amount = len(tt.get_possible_tempi())
            for t, e in tt.get_possible_tempi():
                y_ind = int((t - min(interval)) / accuracy)
                alpha = img[x_ind, y_ind][-1]
                color = 255 * min(1, alpha + 1/amount) * 5
                plot_point(img, x_ind, y_ind, [color] * 3, update_amount)

            for t, e in tt.mins:
                y_ind = int((t - min(interval)) / accuracy)
                alpha = img[x_ind, y_ind][-1]
                err = max(e, min_error) / min_error
                err = 255 / err
                color = [255] * 3 + [err * 20]
                plot_point(img2, x_ind, y_ind, color, update_amount)

            #x_ind += 1
            print(int(100 * ti / len(inputs)), '%')

    im = Image.fromarray(img).rotate(90, expand=1)
    print(im.width, im.height)
    im.save(folder_save + path_to_name(perfo) + "_amount.png")
    im2 = Image.fromarray(img2).rotate(90, expand=1)
    im2.save(folder_save + path_to_name(perfo) + "_error.png")
