import os
import symusic
import pandas as pd
from pathlib import Path

EPSILON = 0.02 # s
DEFAULT_TEMPO = 120 # bpm
path = "../Database/nasap-dataset-main/"

def get_beats_from_txt(ann_path, accept_br=False):
    """Get the beats time from the text annotations

    Arguments:
        ann_path {string} -- the path of the text annotations

    Returns:
        [list] -- a list of beat onsets
    """
    ann_df = pd.read_csv(Path(ann_path),header=None, names=["time","time2","type"],sep='\t')
    if accept_br:
        return ann_df["time"].tolist()
    return [a["time"] for i,a in ann_df.iterrows() if a["type"].split(",")[0] != "bR"]    

def get_downbeats_from_txt(ann_path):
    """Get the downbeats time from the text annotations

    Arguments:
        ann_path {string} -- the path of the text annotations

    Returns:
        [list] -- a list of downbeat onsets
    """
    ann_df = pd.read_csv(Path(ann_path),header=None, names=["time","time2","type"],sep='\t')
    downbeats = [a["time"] for i,a in ann_df.iterrows() if a["type"].split(",")[0] == "db"]
    return downbeats

def get_br_ind_from_txt(ann_path):
    ann_df = pd.read_csv(Path(ann_path),header=None, names=["time","time2","type"],sep='\t')
    return [i for i,a in ann_df.iterrows() if a["type"].split(",")[0] == "bR"]

def get_interpolated_beats_index_from_txt(folder_path, midi = "midi_score", ann = "_annotations.txt", accept_br=False):
    """Get the interpolated beats indexes

    Arguments:
        folder_path {string} -- the path of the folder containing the midi file annotations, and the midi file

    Returns:
        [list] -- a list of indexes representing the interpolated beat
    """
    exact_indexes = []
    delta = EPSILON
    midi_file = symusic.Score(folder_path + midi + ".mid", ttype="second")
    beats = get_beats_from_txt(folder_path + midi + ann, accept_br=accept_br)
    for t in midi_file.tracks:
        for n in t.notes:
            i = 0
            c = 1
            while (c == 1):
                while (i < len(beats) and abs(n.start - beats[i]) < delta):
                    if not i in exact_indexes: # According to the paper figures, only the start of the note is considered
                        exact_indexes.append(i)
                    i += 1
                
                if i >= len(beats):
                    c = 2 # End of track
                    break

                if n.start > beats[i]:
                    i += 1
                else:
                    c = 0

            if c == 2:
                break
    if accept_br:
        br_list = get_br_ind_from_txt(folder_path + midi + ann)
        return [i for i in range(len(beats)) if not i in exact_indexes or i in br_list]
    return [i for i in range(len(beats)) if not i in exact_indexes]

import partitura as pt

def access_by_id(notes, key_id="id"):
    result = {}
    for i in range(len(notes[key_id])):
        result[notes[key_id][i]] = notes[i]
    return result

def get_matching_from_txt(midi_path, separate_hands=False):
    """ Return a decoded version of a matching of the performance """
    path_ = ""
    for i in midi_path.split('/')[:-1]:
        path_ += i + "/"
    xml_score = pt.musicxml_to_notearray(path_ + "xml_score.musicxml", flatten_parts=separate_hands, include_time_signature=True)
    xml = access_by_id(xml_score)
    midi_score = pt.load_performance_midi(midi_path).note_array()
    midi = access_by_id(midi_score)

    path = ""
    for i in midi_path.split('.')[:-1]:
        path += i + "."

    result_matching = []
    _, alignment = pt.load_match(path + "match", create_score=False)
    alignment.sort(key = lambda x: midi[x['performance_id']]["onset_sec"] if x['label'] == 'match' else -1)
    for matching in alignment:
        if matching["label"] != "match":
            continue
        midi_id = matching["performance_id"]
        xml_id = matching["score_id"]
        xml_note = xml[xml_id]
        midi_note = midi[midi_id]
        if len(result_matching) == 0 or (midi_note["onset_sec"] - result_matching[-1][1]["onset_sec"] > EPSILON and xml_note["onset_beat"] > result_matching[-1][0]["onset_beat"]):
            result_matching.append((xml_note, midi_note))

    if separate_hands:
        p = pt.load_score(path_ + "xml_score.musicxml", force_note_ids=True).parts[0]
        left_hand = result_matching
        right_hand = []
        for n in p.notes:
            ind = 0
            while ind < len(left_hand):
                xml_note = left_hand[ind][0]
                if n.id == xml_note["id"].split('-')[0]:
                    if n.staff == 1: # Right hand
                        right_hand.append(left_hand.pop(ind))
                    break
                else:
                    ind+=1
        return left_hand, right_hand

    return result_matching

def find_recursive(l, current_path, rec=False):
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
                find_recursive(l, current_path + '/' + f, rec=rec)

def fit_matching(inp, type="onset", unit="beat"):
    return [(score_note[type + "_" + unit], real_note[type + "_sec"]) for score_note, real_note in inp]

def get_current_piece(perfo, path):
    """ Return only the name of the current composition """
    k = len(path.split('/'))
    for i in perfo.split('/')[k:-1]:
        s += i + '/'
    return s