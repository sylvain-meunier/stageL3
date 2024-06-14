from large_et_al import *
from util import get_beats_from_txt, get_downbeats_from_txt, get_interpolated_beats_index_from_txt, EPSILON, DEFAULT_TEMPO

import os
import numpy as np
import partitura as pt
import matplotlib.pyplot as plt

# Méthode de Large & Jones sur les mêmes données que l'approche naïve

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

def get_nb_beat_before_down(beat_list, next_down_beat):
    """ Return the amount of beats before the next down beat """
    assert(next_down_beat > beat_list[0])
    for i in range(len(beat_list)):
        if abs(beat_list[i] - next_down_beat) < EPSILON / 10:
            return i

path = "../Database/nasap-dataset-main/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"
folder_path = "Bach/Prelude/bwv_876/"
#folder_path = "Bach/Italian_concerto/"
#folder_path = "Chopin/Ballades/2/"
#folder_path = "Liszt/Sonata/"
folder_path = "Beethoven/Piano_Sonatas/18-2_no_repeat/"
folder_path = "Mozart/Piano_sonatas/11-3"

if folder_path[-1] != "/":
    folder_path += "/"

corpus = []

DEFAULT_TEMPO = 110

for f in os.listdir(path + folder_path):
    f = f.split('.')
    if f[-1] != "mid" or "midi_score" in f[0]:
        continue
    corpus.append(Piece(f[0][:-3], path + folder_path + f[0]))

tempo_curves = []

xml_score = pt.musicxml_to_notearray(path + folder_path + "xml_score.musicxml", include_time_signature=True)
xml_id_to_duration = note_id_to_duration(xml_score, key_duration="duration_quarter")
xml_id_to_onset = note_id_to_duration(xml_score, key_duration="onset_quarter")
xml_id_to_beat_onset = note_id_to_duration(xml_score, key_duration="onset_beat")

xml_id_to_ts = {}
for i in range(len(xml_score["id"])):
    xml_id_to_ts[xml_score["id"][i]] = (xml_score["ts_beats"][i], xml_score["ts_beat_type"][i])

ref_beat_list = get_beats_from_txt(path + folder_path + "midi_score_annotations.txt", accept_br=True)
ref_downbeat_list = get_downbeats_from_txt(path + folder_path + "midi_score_annotations.txt")
interpolated_indexes = get_interpolated_beats_index_from_txt(path + folder_path, accept_br=True)
print(len(interpolated_indexes), "beats interpolated, and thus ignored out of", len(ref_beat_list))

for piece in corpus[:1]:
    for i in range(10):
        tempo_curves.append([])

    piece.midi = pt.load_performance_midi(piece.path)
    n_array = piece.midi.note_array()
    noteid_to_duration = note_id_to_duration(n_array)
    noteid_to_onset = note_id_to_duration(n_array, key_duration="onset_sec")
    perf, alignment = pt.load_match(piece.alignment, create_score=False)

    # With score
    #tempo_model1 = Oscillateur(tempo_init=DEFAULT_TEMPO, eta_s=0.20, phase_coupling=1.9, period_coupling=0.35, min_kappa=1)
    tempo_model1 = Oscillateur(tempo_init=DEFAULT_TEMPO, eta_s=0.9, min_kappa=1)
    # Without score
    tempo_model2 = Oscillateur2(tempo_init=DEFAULT_TEMPO, eta_s=0.8, min_kappa=1, eta_phi=1.9, eta_p=0.3)
    # Timekeeper model (scoreless)
    tempo_model3 = TimeKeeper(tempo_init=DEFAULT_TEMPO, alpha=0.4, beta=0.1)

    # naive 2 initialization
    piece_beat_list = get_beats_from_txt(piece.annotations)
    piece_downbeat_list = get_downbeats_from_txt(piece.annotations)
    current_down_beat_ind = 0
    current_beat_ind = 0
    current_quarter = current_down_quarter = -1
    next_downbeat = next_quarter = 0
    nb_beat = None
    time_signature = (4, 4) # by default

    # Large & al estimation, naive 4
    for matching in alignment:
        if matching["label"] != "match":
            continue
        length = noteid_to_duration[matching["performance_id"]]
        expected_length = xml_id_to_duration[matching["score_id"]]

        # Ignore unsignificant value
        if (expected_length < EPSILON or length < EPSILON):
            estimated_tempo = 1
        else:
            estimated_tempo = expected_length / length

        tempo_curves[-1].append(estimated_tempo)
        reference_quarter = xml_id_to_onset[matching["score_id"]]
        reference_beat = xml_id_to_beat_onset[matching["score_id"]]

        time_input = noteid_to_onset[matching["performance_id"]] # second
        tempo_curves[-2].append(time_input)

        if current_beat_ind + 1 < len(piece_beat_list) and time_input >= piece_beat_list[current_beat_ind + 1]:
            tempo_model1.update_and_return_tempo(current_beat_ind, piece_beat_list[current_beat_ind]) # Forçage au tempo
        
        tempo_curves[-7].append(tempo_model1.update_and_return_tempo(reference_beat, time_input))

        is_interpolated = current_beat_ind in interpolated_indexes
        if current_down_beat_ind + 1 < len(piece_downbeat_list) and (current_down_quarter < 0 or different_time_signature(time_signature, xml_id_to_ts[matching["score_id"]]) or reference_quarter >= next_downbeat) : # time signature change or end of measure
            current_down_quarter = reference_quarter # start of new measure
            time_signature = xml_id_to_ts[matching["score_id"]]
            next_downbeat = current_down_quarter + (4 / time_signature[1]) * time_signature[0]
            nb_beat = get_nb_beat_before_down(ref_beat_list[current_beat_ind:], ref_downbeat_list[current_down_beat_ind + 1])
            tempo_model1.set_nb_beat(nb_beat)

            if not is_interpolated:  # ignore interpolated beats
                length = piece_downbeat_list[current_down_beat_ind + 1] - piece_downbeat_list[current_down_beat_ind]
                expected_length = ref_downbeat_list[current_down_beat_ind + 1] - ref_downbeat_list[current_down_beat_ind]
                # Ignore unsignificant value
                if (expected_length < EPSILON or length < EPSILON):
                    estimated_tempo = 1
                else:
                    estimated_tempo = expected_length / length
                tempo_curves[-5].append(estimated_tempo)
                # Estimation according to Large & Jones model, relative to 120 bpm
                tempo_curves[-6].append(time_input)
            current_down_beat_ind += 1

        if current_beat_ind + 1 < len(piece_beat_list) and (current_quarter < 0 or reference_quarter >= next_quarter) :
            current_quarter = reference_quarter # new quarter
            next_quarter = current_quarter + (4 / time_signature[1]) * time_signature[0] / nb_beat
            if not is_interpolated:
                length = piece_beat_list[current_beat_ind + 1] - piece_beat_list[current_beat_ind]
                expected_length = ref_beat_list[current_beat_ind + 1] - ref_beat_list[current_beat_ind]
                # Ignore unsignificant value
                if (expected_length < EPSILON or length < EPSILON):
                    estimated_tempo = 1
                else:
                    estimated_tempo = expected_length / length
                tempo_curves[-3].append(estimated_tempo)
                tempo_curves[-4].append(time_input)
                tempo_curves[-8].append(tempo_model2.update_and_return_tempo(time_input, iter=1))
                tempo_curves[-9].append(tempo_model3.update_and_return_tempo(time_input))
            current_beat_ind += 1

    plt.yscale("log")
    #plt.plot(tempo_curves[-2], tempo_curves[-1], '.', color="lightgray", markersize=2, label="tempo per note (n4)")
    plt.plot(tempo_curves[-4], [i * 120 for i in tempo_curves[-3]], '.', color="blue", markersize=5, label="tempo per quarter (n2)")
    plt.plot(tempo_curves[-6], [i * 120 for i in tempo_curves[-5]], '.', color="red", markersize=5, label="tempo per measure (n2)")
    plt.plot(tempo_curves[-2], tempo_curves[-7], '-', color="black" , markersize=2, label="Large 2010")
    plt.plot(tempo_curves[-4], tempo_curves[-8], '-', color="yellow" , markersize=2, label="Large 1999")
    plt.plot(tempo_curves[-4], tempo_curves[-9], '--', color="orange" , markersize=2, label="Timekeeper")

    plt.title("Tempo curve for " + piece.name + " (comparison 2)")
    plt.xlabel("Time (second)")
    plt.ylabel("Tempo (bpm)")
    plt.legend()
    #plt.savefig(piece.name + ".png", format="png")
    plt.show()

    # Analyse stat à faire