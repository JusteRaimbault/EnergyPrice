import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math

np.random.seed(12345)

J = 100
N = 1000
eta = 1
P = 0.8

class Station:

    def __init__(self, j):
        self.x = math.cos(j/J*2*math.pi)
        self.y = math.sin(j/J*2*math.pi)
        self.price = 1
        self.j = j
        self.next = None
        self.prev = None

    def Theta(self):
        pj = self.price
        pj1 = self.next.price
        y = 1/eta*(pj1-pj)/(pj1+pj)+2*math.pi*self.j/J+2*math.pi/J*pj1/(pj1+pj)
        return y;

class Consumer:

    def __init__(self, Theta):
        self.x = math.cos(Theta)
        self.y = math.sin(Theta)
        self.Theta = Theta


def next_GS(GS, list_station):
    if GS.j == J-1:
        y = 0
    else:
        y = GS.j+1
    return list_station[y];
def prev_GS(GS, list_station):
    if GS.j == 0:
        y = J-1
    else:
        y = GS.j-1
    return list_station[y];

list_station = []
for j in range(J):
    list_station.append(Station(j))

for GS in list_station:
    GS.next= next_GS(GS, list_station)
    GS.prev= prev_GS(GS, list_station)

list_consum = []
for n in range(N):
    Theta = np.random.uniform(N, size = 1)/N*2*math.pi
    list_consum.append(Consumer(Theta))

X = []
Y = []
for C in list_consum:
    X.append(C.x)
    Y.append(C.y)

X_s = []
Y_s = []

for S in list_station:
    X_s.append(S.x)
    Y_s.append(S.y)

plt.figure(figsize=(8,8))
plt.scatter(X,Y,marker='+',color='green')
plt.scatter(X_s,Y_s,marker='o',color='red')
plt.show()

def profit(GS, list_consum):
    demand = 0
    for i in range(N):
        if (list_consum[i].Theta > GS.prev.Theta() and list_consum[i].Theta<GS.Theta()):
            demand = demand + 1
    y = (GS.price - P)*demand
    return y;
