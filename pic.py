import time
import pickle as pi

class Timer():
    def __init__(self, maxi, current=0, msg="Loading data :", end="Task done.") -> None:
        self.maxi = maxi
        self.current = current
        self.progress = self.get_progress()
        self.msg = msg
        self.end = end

    def get_progress(self) :
        return int((self.current * 100) / self.maxi)
    
    def update(self):
        self.current += 1
        tmp = self.get_progress()
        if tmp > self.progress:
            print(self.msg, self.progress, "%")
            self.progress = tmp
        if self.current == self.maxi:
            print(self.end)


def save(perfo, data, path="measure.txt", limit=2+5):
    with open(path, 'a') as f:
        if perfo is not None:
            f.write(perfo + ',')
        for d in data[:-1]:
            f.write(str(d)[:limit] + ',') # 5 decimal precision
        f.write(str(data[-1])[:limit] + '\n')

def exec_from_txt(path, fct, t, already_done=[]):
    try:
        with open(path, 'r') as f:
            for line in f:
                dec = line.split(',')
                if len(dec) < 2:
                    continue
                if dec[0] not in already_done:
                    fct(dec[0], [float(i) for i in dec[1:]])
                t.update()
    except:
        pass

def load_from_txt(path, nb_line=1018):
    l = []
    t = Timer(nb_line)
    exec_from_txt(path, lambda x, y : l.append([x] + y), t)
    return l

def txt_to_pickle(path="measure.txt"):
    l = load_from_txt(path)

    with open(path.split('.')[0] + ".pick", 'wb') as f:
        pi.dump(l, f)

def load_pick(path="measure.pick"):
    with open(path, 'rb') as f:
        return pi.load(f, encoding="UTF-8")

def load_done(path="measure.txt"):
    p = load_from_txt(path=path)
    return [i[0] for i in p]



def test_perf():
    t = time.time()
    load_from_txt("measure.txt")
    print("ELAPSED TIME FOR LOADING TXT",time.time() - t) # 96 s
    t = time.time()
    l = load_pick()
    print("ELAPSED TIME FOR LOADING PICK",time.time() - t) # 20.5s