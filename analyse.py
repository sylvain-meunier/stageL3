from pic import load_pick, Timer, save, load_done, exec_from_txt
from large_et_al import measure

NB_LINE = 1018

#data = load_pick("measure.pick")
#already_done = load_done("performance_test.txt")
t = Timer(NB_LINE, msg="Saving data :")

exec_from_txt("measure.txt", lambda x, y : save(x, (measure(y, 0.075),), path="performance_test.txt"), t)
# 16:00