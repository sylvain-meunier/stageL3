import os
import numpy as np
import partitura as pt
from util import EPSILON
import matplotlib.pyplot as plt

# Test d'une méthode naïve de détection de tempo
# On assemble toutes les approches précédentes pour une comparaison unifiée

class Piece:
    def __init__(self, name, path, ext=".mid"):
        self.name = name
        self.path = path + ext
        self.annotations = path + "_annotations.txt"
        self.alignment = path + ".match"
        self.midi = None

def note_id_to_duration(notes, key_id="id", key_duration = "duration_sec"):
    noteid_to_duration = {}
    for i in range(len(notes[key_id])):
        noteid_to_duration[notes[key_id][i]] = notes[key_duration][i]
    return noteid_to_duration

def different_time_signature(ts1, ts2, precision=0.001):
    return not(abs(ts1[0] - ts2[0] < precision) and abs(ts1[1] - ts2[1] < precision))

path = "../Database/nasap-dataset-main/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"
folder_path = "Bach/Prelude/bwv_876/"
folder_path = "Bach/Italian_concerto/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"

corpus = []

for f in os.listdir(path + folder_path):
    f = f.split('.')
    if f[-1] != "mid" or "midi_score" in f[0]:
        continue
    corpus.append(Piece(f[0][:-3], path + folder_path + f[0]))

tempo_curves = []

# The following method unfolds the repetition, and thus rename the note identifiers according to the matching file format
xml_score = pt.musicxml_to_notearray(path + folder_path + "xml_score.musicxml", include_time_signature=True)
xml_id_to_duration = note_id_to_duration(xml_score, key_duration="duration_quarter")
xml_id_to_onset = note_id_to_duration(xml_score, key_duration="onset_quarter")

xml_id_to_ts = {}
for i in range(len(xml_score["id"])):
    xml_id_to_ts[xml_score["id"][i]] = (xml_score["ts_beats"][i], xml_score["ts_beat_type"][i])


for piece in corpus[:3]:
    for i in range(6):
        tempo_curves.append([])

    piece.midi = pt.load_performance_midi(piece.path)
    noteid_to_duration = note_id_to_duration(piece.midi.note_array())
    perf, alignment = pt.load_match(piece.alignment, create_score=False)

    current_beat = -1
    current_down_beat = -1
    next_downbeat = 0
    time_signature = (4, 4) # by default

    for matching in alignment:
        if matching["label"] != "match":
            continue
        length = noteid_to_duration[matching["performance_id"]] # s
        expected_length = xml_id_to_duration[matching["score_id"]] # quarter

        # Ignore unsignificant value
        if (expected_length < EPSILON or length < EPSILON):
            estimated_tempo = 1
        else:
            estimated_tempo = expected_length / length

        tempo_curves[-1].append(estimated_tempo)
        reference_quarter = xml_id_to_onset[matching["score_id"]]
        tempo_curves[-2].append(reference_quarter) # time units : quarter

        if current_beat < 0 or int(reference_quarter) > current_beat :
            current_beat = int(reference_quarter) # new quarter
            tempo_curves[-3].append([])
            tempo_curves[-4].append(current_beat)

            if current_down_beat < 0 or different_time_signature(time_signature, xml_id_to_ts[matching["score_id"]]) or reference_quarter >= next_downbeat : # time signature change or end of measure
                current_down_beat = int(reference_quarter) # start of new measure
                time_signature = xml_id_to_ts[matching["score_id"]]
                next_downbeat = current_down_beat + int((4 / time_signature[1]) * time_signature[0])
                tempo_curves[-5].append([])
                tempo_curves[-6].append([current_down_beat])
        
        if len(tempo_curves[-3]) > 0:
            tempo_curves[-3][-1].append(estimated_tempo)

        if len(tempo_curves[-5]) > 0:
            tempo_curves[-5][-1].append(estimated_tempo)

    median = np.median(tempo_curves[-1])

    plt.yscale("log")

    plt.plot((tempo_curves[-2][0], tempo_curves[-2][len(tempo_curves[-1]) - 1]), (median, median), color="green", markersize=2, label="Median")
    plt.plot(tempo_curves[-2], tempo_curves[-1], '.', color="lightgray", markersize=2, label="tempo per note")
    plt.plot(tempo_curves[-4], [np.median(quarter) for quarter in tempo_curves[-3]], '.', color="blue", markersize=5, label="tempo per quarter")
    plt.plot(tempo_curves[-6], [np.average(measure) for measure in tempo_curves[-5]], '.', color="red", markersize=5, label="tempo per measure")
    plt.title("Tempo curve for " + piece.name + " (naive 4)")
    plt.xlabel("Time (quarter)")
    plt.ylabel("Relative tempo to reference sheet at constant 120 bpm")
    plt.legend()
    plt.savefig(piece.name + ".png", format="png")
    plt.show()
    plt.close()

    # Analyse stat à faire