import music21.musicxml.xmlToM21 as xmlimport # Used to decode reference xml file
import matplotlib.pyplot as plt
import symusic

EPSILON = 0.001

# TODO : Les pauses sont-elles comptabilisées dans la détermination du tempo ?

# Test d'une méthode naïve de détection de tempo
# Dans un premier temps, on ne considère que les restrictions monophoniques des pièces

class Piece:
    def __init__(self, name, path, ext=".mid"):
        self.name = name
        self.path = path + ext
        self.annotations = path + "_annotations.txt"
        self.midi = None

def midi_file_to_list(midi_path):
    """
    Returns a sorted list of couple : ($time, note list) containing all note starting at $time
    """
    midi_file = symusic.Score(midi_path, ttype="second")

    print("NB_track for", midi_path[-20:], ":", len(midi_file.tracks))

    for t in midi_file.tracks:
        previous = -1
        for n in t.notes:
            if (previous < 0):
                print(n.start)
                delta = 0.521875 - n.start
            else:
                print(n.start)
            previous = n.start
        print("decalage :", delta)
        print("Fin :", previous)


path = "../Database/asap-dataset-master/"

file_path = "Bach/Italian_concerto/"

corpus = [Piece("MIDI", path + file_path + "midi_score"), Piece("Tanaka", path + file_path + "TanakaM03"), Piece("Lee", path + file_path + "LeeN07")]

tempo_curves = []

MI = xmlimport.MusicXMLImporter()
reference_score = MI.scoreFromFile(path + file_path + "xml_score.musicxml").parts.stream().first()

for piece in corpus:
    piece.midi = midi_file_to_list(piece.path)
    print(piece.name)
    continue

    tempo_curves.append([])
    tempo_curves.append([])

    total_length = 0
    current_beat = 0 # on the reference xml

    # TODO : ignore bR labels (cannot determine exact beat position), not in the test data here

    with open(piece.annotations) as p_annotation:
        for time, (note, ) in piece.midi:
            #length = note_.quarterLength
            length = note.seconds
            total_length += length

            if note.isRest:
                continue

            expected_length = 1

            if (EPSILON > expected_length):
                estimated_tempo = 1
            else:
                estimated_tempo = length / expected_length

            tempo_curves[-1].append(estimated_tempo)
            tempo_curves[-2].append(current_beat + note.offset)

    plt.plot(range(len(tempo_curves[-1])), tempo_curves[-1], '.')
    plt.title("Tempo curve for " + piece.name)
    plt.xlabel("Time (beat)")
    plt.ylabel("Relative tempo to reference sheet")
    plt.show()

    # Analyse stat à faire