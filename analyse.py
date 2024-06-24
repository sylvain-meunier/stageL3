from pic import load_pick, Timer, save, load_done
from large_et_al import measure

data = load_pick("measure.pick")
already_done = load_done("performance_test.txt")
t = Timer(len(data), current=len(already_done), msg="Saving data :")

for d in data[len(already_done):]:
    #if d[0] in already_done:continue
    save(d[0], (measure(d[1:], 0.15),), path="performance_test.txt")
    t.update()