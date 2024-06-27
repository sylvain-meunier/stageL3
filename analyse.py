from pic import load_pick, Timer, save, load_done, exec_from_txt
from large_et_al import measure

NB_LINE = 1018
folder = "Performance/"
pick_path = "random_measure.pick"
save_path = folder + "random_performance_test.txt"

data = load_pick(pick_path)
already_done = load_done(save_path)
t = Timer(NB_LINE, msg="Saving data :")
for d in data[len(already_done):]:
    save(d[0], (measure(d[1:], 0.075),), path=save_path)
    t.update()

#exec_from_txt("measure.txt", lambda x, y : save(x, (measure(y, 0.075),), path="performance_test.txt"), t, already_done=already_done)
# 16:00 - 18h10
# 11:52 - 11h54
