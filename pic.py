import time
import pickle as pi


def save(perfo, data, path="measure.txt"):
    with open(path, 'a') as f:
        f.write(perfo + ',')
        for d in data[:-1]:
            f.write(str(d)[:2+5] + ',') # 5 decimal precision
        f.write(str(data[-1])[:2+5] + '\n')

class Timer():
    def __init__(self, maxi, current=0) -> None:
        self.maxi = maxi
        self.current = current
        self.progress = self.get_progress()

    def get_progress(self) :
        return int((self.current * 100) / self.maxi)
    
    def update(self):
        self.current += 1
        tmp = self.get_progress()
        if tmp > self.progress:
            print("Loading data :", self.progress, "%")
            self.progress = tmp
        if self.current == self.maxi:
            print("Loading done.")


def load_from_txt(path, nb_line=1018):
    l = []
    t = Timer(nb_line)
    with open(path, 'r') as f:
        for line in f:
            dec = line.split(',')
            l.append([dec[0]] + [float(i) for i in dec[1:]])
            t.update()
    return l

def txt_to_pickle(path="measure.txt"):
    l = load_from_txt(path)

    with open("measure.pick", 'wb') as f:
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