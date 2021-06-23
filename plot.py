import numpy as np
import matplotlib.pyplot as plt

time, stddev, threads, version, graphTime, graphStddev, graphThreads = [], [], [], [], [], [], []

for line in open('temp.txt', 'r'):
 	values = [float(s) for s in line.split()]
 	time.append(values[0])
 	stddev.append(values[1])
 	threads.append(int(values[2]))
 	version.append(int(values[3]))

countchangesv = 1;
barWidth=0.1

sizeVersion = int(len(version)/5)

for i in range (0, len(version)):
		if version[i] > version[i-1]:
			countchangesv += 1
		if version[i] < version[i-1]: 
			countchangesv=1

qtdThreads=int(len(threads)/(9*countchangesv))

for g in range (0,9): #9 benchmarks
	fig = plt.figure(figsize=(15,10))
	fig = plt.gcf()

	for v in range (0, countchangesv): #5 versions
		graphTime.clear()
		graphStddev.clear()
		graphThreads.clear()

		for i in range (0,qtdThreads): #qtd de threads marcados no gráfico
			graphTime.append(time[i*9+g+v*sizeVersion])
			graphStddev.append(stddev[i*9+g+v*sizeVersion])
			graphThreads.append(threads[i*9+g+v*sizeVersion])

		r1 = np.arange(len(graphThreads))
		r2 = [x + barWidth for x in r1]
		r3 = [x + barWidth for x in r2]
		r4 = [x + barWidth for x in r3]
		r5 = [x + barWidth for x in r4]

		if v==0:
			plt.bar(r1, graphTime, width=barWidth, edgecolor='black', label = "Linux")
			plt.errorbar(r1, graphTime, graphStddev, marker='^', linestyle='None', color='black')
			plt.xticks(r1, graphThreads, rotation ='horizontal')

		if v==1:
			plt.bar(r2, graphTime, width=barWidth, edgecolor='black', label = "Round Robin (RAM)")
			plt.errorbar(r2, graphTime, graphStddev, marker='^', linestyle='None', color='black')
			plt.xticks(r2, graphThreads, rotation ='horizontal')

		if v==2:
			plt.bar(r3, graphTime, width=barWidth, edgecolor='black', label = "Compact (RAM)")
			plt.errorbar(r3, graphTime, graphStddev, marker='^', linestyle='None', color='black')
			plt.xticks(r3, graphThreads, rotation ='horizontal')

		if v==3:
			plt.bar(r4, graphTime, width=barWidth, edgecolor='black', label = "Compact (Threads)")
			plt.errorbar(r4, graphTime, graphStddev, marker='^', linestyle='None', color='black')
			plt.xticks(r4, graphThreads, rotation ='horizontal')

		if v==4:
			plt.bar(r5, graphTime, width=barWidth, edgecolor='black', label = "Scatter (Threads")
			plt.errorbar(r5, graphTime, graphStddev, marker='^', linestyle='None', color='black')
			plt.xticks(r5, graphThreads, rotation ='horizontal')

	plt.ylabel('Tempo de execução (s)')
	plt.xlabel('Número de threads')

	if g==0:
		filename = "Genome"
	if g==1:
		filename = "Intruder" 
	if g==2:
		filename = "KmeansLow" 
	if g==3:
		filename = "KmeansHigh" 
	if g==4:
		filename = "Labyrinth" 
	if g==5:
		filename = "Ssca2" 
	if g==6:
		filename = "VacationLow" 
	if g==7:
		filename = "VacationHigh" 
	if g==8:
		filename = "Yada" 

	plt.title("Tinystm " + filename + " Benchmarks")
	plt.legend()
	plt.grid()
	plt.draw()

	fig.savefig('Graphs/'+"graph"+filename+".png")

	graphTime.clear()
	graphStddev.clear()
	graphThreads.clear()
