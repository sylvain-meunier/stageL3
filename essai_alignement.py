# https://github.com/CPJKU/asap-dataset

# FICHIER marqué en TODO éventuel, pour un algorithme d'alignement des notes

from heapq import *
from symusic import Note

EPSILON = 0.02 # s

def epsicut(performance, epsilon=EPSILON):
    if len(performance) < 2:
        return performance, [], []

    in_measure = []
    in_between = []
    others = []
    for measure in performance:
        for note in measure:
            if note.start < performance[1] - EPSILON:


    return in_measure, in_between, others

class Partial_alignment:
    def __init__(self):
        """
        Encoding of a partial function from reference sequence to performance sequence
        """

def sequence_alignment(ref_bd_list, perf_db_list):
    """
    Any local sequence alignment algorithm
    """

def best_first_search(ref_db_list, perf_db_list):
    queue = heapify([])
    heappush(queue, )

    while 1:
        try:
            (current_db_ref, current_db_perf) = heappop(queue)

            in_measure, in_between, others = epsicut(ref_db_list[current_db_ref:], perf_db_list[current_db_perf:])

        except:
            raise Exception("Unexpected Error")
