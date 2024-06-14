import os
import numpy as np
import matplotlib.pyplot as plt
from util import get_beats_from_txt, get_downbeats_from_txt

EPSILON = 0.001

# Test d'une méthode naïve de détection de tempo

class Piece:
    def __init__(self, name, path, ext=".mid"):
        self.name = name
        self.path = path + ext
        self.annotations = path + "_annotations.txt"
        self.midi = None


def evaluate_poly(coeffs, x):
    a = 1
    result = 0
    for c in coeffs:
        result += a * c
        a *= x
    return result

path = "../Database/asap-dataset-master/"
file_path = "Bach/Italian_concerto/"
corpus = []

for f in os.listdir(path + file_path):
    f = f.split('.')
    if f[-1] != "mid" or "midi_score" in f[0]:
        continue
    corpus.append(Piece(f[0][:-3], path + file_path + f[0]))

print(corpus)

ref_beat_list = get_beats_from_txt(path + file_path + "midi_score_annotations.txt")
ref_downbeat_list = get_downbeats_from_txt(path + file_path + "midi_score_annotations.txt")

tempo_curves = []

for piece in corpus:
    tempo_curves.append([])
    tempo_curves.append([])

    piece_beat_list = get_beats_from_txt(piece.annotations)
    piece_downbeat_list = get_downbeats_from_txt(piece.annotations)

    beat_list = []
    current_down_beat = 0

    for current_beat in range(len(piece_beat_list) - 1):
        length = piece_beat_list[current_beat + 1] - piece_beat_list[current_beat]
        expected_length = ref_beat_list[current_beat + 1] - ref_beat_list[current_beat]

        # Ignore unsignificant value
        if (expected_length < EPSILON or length < EPSILON):
            estimated_tempo = 1
        else:
            estimated_tempo = expected_length / length

        tempo_curves[-1].append(estimated_tempo)

        if abs(piece_beat_list[current_beat] - piece_downbeat_list[current_down_beat]) < EPSILON:
            tempo_curves[-2].append([])
            current_down_beat += 1

        tempo_curves[-2][-1].append(estimated_tempo)

    median = np.median(tempo_curves[-1])

    plt.plot(range(len(tempo_curves[-1])), tempo_curves[-1], '.', color="blue")
    plt.plot(range(len(tempo_curves[-1])), [np.median(measure) for measure in tempo_curves[-2] for b in measure], '.', color="red")
    plt.plot((0, len(tempo_curves[-1]) - 1), (median, median), color="green")
    #coeffs = np.polyfit(range(len(tempo_curves[-2])), [np.median(measure) for measure in tempo_curves[-2]], deg=0)
    #plt.plot(range(len(tempo_curves[-1])), [evaluate_poly(coeffs, x) for x in range(len(tempo_curves[-1]))], color='gray')
    plt.title("Tempo curve for " + piece.name)
    plt.xlabel("Time (beat)")
    plt.ylabel("Relative tempo to reference sheet")
    plt.savefig(piece.name + "_med.png", format="png")
    plt.show()
    plt.close()

'''
    plt.plot(piece_beat_list[:-3], tempo_curves[-1], '.', color="blue")
    plt.plot(piece_beat_list[:-3], tempo_curves[-2], '.', color="red")
    plt.title("Tempo curve for " + piece.name)
    plt.xlabel("Time (s)")
    plt.ylabel("Relative tempo to reference sheet")
    plt.savefig(piece.name + "_time.png", format="png")
    plt.show()
    plt.close()
'''

    # Analyse stat à faire