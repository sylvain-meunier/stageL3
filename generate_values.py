import numpy as np
from large_et_al import Estimator, RandomEstimator, TempoTracker, measure, normalize_tempo
from util import get_matching_from_txt, fit_matching, find_recursive, path, EPSILON
from pic import load_done, save, Timer, txt_to_pickle
import matplotlib.pyplot as plt

save_file = "measure.txt"

init_bpm = 40
l = []
find_recursive(l, path, rec=True)
nb_piece = 0
already_done = load_done(save_file)

timer = Timer(1018, current=len(already_done))

for perfo in l:
    if perfo in already_done:
        continue
    try:
        matching = get_matching_from_txt(perfo + ".mid")
        inputs = fit_matching(matching)
        nb_piece += 1
    except:
        continue

    tt = TempoTracker(Estimator(accuracy=250), init_bpm)
    results = ([], [], [])

    for ti in range(len(inputs)-1):
        beat_input, time_input = inputs[ti]
        results[0].append(time_input)
        results[1].append(((inputs[ti+1][0] - beat_input) * 60 / (inputs[ti+1][1] - time_input)))
        results[2].append(tt.update_and_return_tempo(time_input))

    tmp = results[2]
    tmp2 = results[1]
    tmp = [normalize_tempo(tmp[i+1] / tmp2[i]) for i in range(len(tmp2) - 1)]
    #save(perfo, tmp, path=save_file)
    if "11-3" in perfo:
        plt.hist(tmp, bins=100)
        plt.title(str(perfo) + " " + str(measure(tmp, 0.075))[:8])
        plt.show()
        exit(0)
    timer.update()

txt_to_pickle(path=save_file)