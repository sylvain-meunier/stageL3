import os
import numpy as np
import partitura as pt
import matplotlib.pyplot as plt

EPSILON = 0.001

# Test d'une méthode naïve de détection de tempo
# On essaie à présent de calculer nos ratios note par note

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

path = "../Database/nasap-dataset-main/"
folder_path = "Beethoven/Piano_Sonatas/18-2/"
folder_path = "Bach/Italian_concerto/"

folder_path = "Chopin/Ballades/2/"
folder_path = "Liszt/Sonata/"
folder_path = "Bach/Prelude/bwv_876/"

corpus = []

for f in os.listdir(path + folder_path):
    f = f.split('.')
    if f[-1] != "mid" or "midi_score" in f[0]:
        continue
    corpus.append(Piece(f[0][:-3], path + folder_path + f[0]))

tempo_curves = []

# score = None # We cannot load the score from a .xml file, since the notes ids does not correspond to the specification in .match, and general alignments...

# xml_score = pt.load_musicxml(path + folder_path + "xml_score.musicxml")[0]

xml_score = pt.musicxml_to_notearray(path + folder_path + "xml_score.musicxml")
xml_id_to_duration = note_id_to_duration(xml_score, key_duration="duration_beat")
xml_id_to_onset = note_id_to_duration(xml_score, key_duration="onset_beat")
# dans la spec, un -1 indique qu'il s'agit de la première répétition, pas dans le fichier -> algo pour tout remettre bien, ou inférence et on croise les doigts ?
# contrib : mettre les bons identifiants dans les xml ? (2h)
# lien naif entre les deux identifiants, à confirmer... OUI, mais inutile dans notre cas (et dans le cas général)

for piece in corpus[:3]:
    tempo_curves.append([])
    tempo_curves.append([])

    piece.midi = pt.load_performance_midi(piece.path)
    noteid_to_duration = note_id_to_duration(piece.midi.note_array())

    #if score is None:
        #perf, alignment, score = pt.load_match(piece.alignment, create_score=True)
    #else:
    perf, alignment = pt.load_match(piece.alignment, create_score=False)

    for matching in alignment:
        if matching["label"] != "match":
            continue
        length = noteid_to_duration[matching["performance_id"]]
        # xml_id = matching["score_id"].split("-")[0] # Get actual id, ignoring the repaeat number ; format : $xml_id$-$repeat_number$
        expected_length = xml_id_to_duration[matching["score_id"]]

        # Ignore unsignificant value
        if (expected_length < EPSILON or length < EPSILON):
            estimated_tempo = 1
        else:
            estimated_tempo = expected_length / length

        tempo_curves[-1].append(estimated_tempo)
        tempo_curves[-2].append(xml_id_to_onset[matching["score_id"]]) # time units : beats

    median = np.median(tempo_curves[-1])

    plt.plot(tempo_curves[-2], tempo_curves[-1], '.', color="magenta", markersize=2)
    plt.plot((tempo_curves[-2][0], tempo_curves[-2][len(tempo_curves[-1]) - 1]), (median, median), color="green")
    plt.title("Tempo curve for " + piece.name + " (naive 3)")
    plt.xlabel("Time (beat)")
    plt.ylabel("Relative tempo to reference sheet")
    plt.savefig(piece.name + "_med.png", format="png")
    plt.show()
    plt.close()

    # Analyse stat à faire