import numpy as np
from large_et_al import *
from util import get_matching_from_txt, fit_matching, find_recursive, path, EPSILON
from pic import load_done, save, Timer, txt_to_pickle
import matplotlib.pyplot as plt

save_file = "random_measure.txt"

init_bpm = 120
tt = TempoTracker(RandomEstimator(), tempo_init=init_bpm)

l = []
find_recursive(l, path, rec=True)
ratio = []
nb_piece = 0
already_done = load_done(save_file)
results = ([], [], [])

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

    for ti in range(len(inputs)-1):
        beat_input, time_input = inputs[ti]
        results[0].append(time_input)

        if inputs[ti+1][1] - time_input > EPSILON:
            results[1].append(((inputs[ti+1][0] - beat_input) * 60 / (inputs[ti+1][1] - time_input)))
            results[2].append(tt.update_and_return_tempo(time_input, debug=0))

    tmp = [normalize_tempo(i, min=1, max=2) for i in np.array(results[2][1:]) / np.array(results[1][:-1])]
    save(perfo, tmp, path=save_file)
    timer.update()

plt.yscale("linear")
plt.hist(ratio, bins=100)
plt.title("A view of Random TempoTracker performance for the whole (n)-ASAP dataset (" + str(nb_piece) + " pieces)")
plt.show()

txt_to_pickle(path=save_file)