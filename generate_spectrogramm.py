import numpy as np
from PIL import Image
import matplotlib.pyplot as plt
from models import QuantiTracker
from util import EPSILON, get_matching_from_txt, fit_matching, path, find_recursive

init_bpm = 100
tt = QuantiTracker(init_bpm)

inputs = []
results = ([], [], [], [], [], [], [], [], [])

folder_path = "Prokofiev/Toccata/"
folder_path = "Bach/Italian_concerto/"
folder_path = "Brahms/Six_Pieces_op_118/2/"
folder_path = "Liszt/Sonata/"
folder_path = "Schumann/Toccata/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"
folder_path = "Balakirev/Islamey/"
folder_path = "Mozart/Piano_sonatas/11-3/"

folder_save = "./Spectros/"

def path_to_name(path_):
    return path_[len(path):].replace('/', '_').replace('.', '')

l = []

radius = 3
circle = []
for i in range(-radius, radius+1):
    for j in range(-radius, radius+1):
        if i**2 + j**2 <= radius**2:
            circle.append((i, j))

def plot_point(tab, x, y, color, update):
    for i, j in circle:
        if 0 <= (x + i) < len(tab) and 0 <= (y + j) < len(tab[0]):
            update(tab, x+i, y+j, color)

find_recursive(l, path + folder_path, rec=1)

def update_amount(tab, x, y, color):
    tab[x, y] = [min(c, 255) for c in color]

def update_error(tab, x, y, color):
    alpha = tab[x, y][-1]
    tmp = np.array([int(min(c, 255)) for c in color])
    if alpha < 1:
        tab[x, y] = np.array([int(min(c, 255)) for c in color])
    else:
        if tmp[0] > tab[x, y][0]:
            tab[x, y] = tmp

def extend_image(im, x_inds, image_width, image_height):
    for x in range(1, image_width):
        if not x in x_inds:
            for y in range(image_height):
                im[x, y] = im[x-1, y]

def invert_image(im, image_width, image_height):
    for x in range(image_width):
        for y in range(image_height):
            if im[x, y][0] == 0:
                im[x, y] = [255] * 3
            else:
                im[x, y] = [0] * 3

for perfo in l[:1]:
    matching = get_matching_from_txt(perfo + ".mid")
    inputs = fit_matching(matching, unit="quarter")

    tatum = 1 / 60 # quarter
    maxinput = inputs[-1][0] # quarter
    # image_width = int(maxinput / tatum) + 1
    image_width = len(inputs)-1
    interval = tt.get_interval()
    accuracy = 1/2 # quarter per minute
    image_height = int(abs(interval[0] - interval[1]) / accuracy) + 1
    img = np.zeros((image_width, image_height, 3), dtype=np.uint8)
    img2 = np.zeros((image_width, image_height, 3), dtype=np.uint8)
    x_inds = []
    print(image_width, image_height)

    for ti in range(len(inputs)-1):
            beat_input, time_input = inputs[ti]

            x_ind = int((beat_input / maxinput) * image_width)
            x_inds.append(x_ind)

            tt.update_and_return_tempo(time_input)

            amount = len(tt.get_possible_tempi())
            for t, e in tt.get_possible_tempi():
                y_ind = int((t - min(interval)) / accuracy)
                if abs(e) < 0.000000001:
                    err = 1
                else:
                    err = min(1, 0.0001/e)
                color = [255] * 3
                plot_point(img, x_ind, y_ind, color, update_error)

            for y_ind in range(image_height):
                continue
                t = y_ind * accuracy + min(interval)
                if len(tt.T) == 0:
                    continue
                e = error(1/t, tt.T)

                err = min(1, 0.00008/e)
                color = [255 * err] * 3
                plot_point(img2, x_ind, y_ind, color, update_error)

            print(int(100 * ti / len(inputs)), '%')

    #extend_image(img, x_inds, image_width, image_height)
    invert_image(img, image_width, image_height)
    im = Image.fromarray(img).rotate(90, expand=1)
    im.save(folder_save + path_to_name(perfo) + "_amount.png")
    exit(0)
    
    extend_image(img2, x_inds, image_width, image_height)
    im2 = Image.fromarray(img2).rotate(90, expand=1)
    im2.save(folder_save + path_to_name(perfo) + "_error.png")
