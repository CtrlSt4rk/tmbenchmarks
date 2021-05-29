#!/bin/bash

function threadsConfig(){
	threads=$( grep -c ^processor /proc/cpuinfo )
	if [ $threads -gt 16 ]
	then
		interval=8
	else
		interval=4
	fi
}

function lscpuInfo(){
	lscpu > lscpuLog.txt
	grep -f filtroLscpu.txt lscpuLog.txt > lscpuTemp.txt
	sed -e 's/.*://' -e 's/  */ /g' lscpuTemp.txt > lscpuCompact.txt
	rm lscpuTemp.txt

	currNode=0
	nodesInUse=0

	cores=$( grep -c ^processor /proc/cpuinfo )
	nodeCount=$(wc -l lscpuCompact.txt | awk '{ print $1 }')
	coresPerNode=$((cores/nodeCount))

	currNode=$((threads%coresPerNode))

	for ((node=1; node<$nodeCount; node++))
	do
		if [ $node -le $((nodeCount-1)) ]
		then
			nodesInUse="$nodesInUse,"
		fi
		nodesInUse="$nodesInUse$node"
	done
}

function benchConfig(){
	
	for (( i=0; i<=$threads; i=i+$interval ))
	do
		if [ $i -eq 0 ]
		then
			i=1
		fi

		for ((j=1; j<=$testQtd; j++))
		do
			$versionApp ./stamp/tinystm/genome/genome -g16384 -s64 -n16777216 -t${i} >> tempUn.txt
		done
			dataProcess
			stats
		for ((j=1; j<=$testQtd; j++))
		do
			$versionApp ./stamp/tinystm/intruder/intruder -a10 -l128 -n262144 -s1 -t${i} >> tempUn.txt
		done
			dataProcess
			stats
		
		for ((j=1; j<=$testQtd; j++))
		do
			$versionApp ./stamp/tinystm/kmeans/kmeans -m40 -n40 -T0.00001 -i stamp/data/kmeans/inputs/random-n65536-d32-c16.txt -L -t${i} >> tempUn.txt #low contention
		done
			dataProcess
			stats
		
		for ((j=1; j<=$testQtd; j++))
		do
			$versionApp ./stamp/tinystm/kmeans/kmeans -m15 -n15 -T0.00001 -i stamp/data/kmeans/inputs/random-n65536-d32-c16.txt -t${i} >> tempUn.txt #high contention
		done
			dataProcess
			stats
		
		for ((j=1; j<=$testQtd; j++))
		do
			$versionApp ./stamp/tinystm/labyrinth/labyrinth -i stamp/data/labyrinth/inputs/random-x512-y512-z7-n512.txt -t${i} >> tempUn.txt 
		done	
			dataProcess
			stats
		
		for ((j=1; j<=$testQtd; j++))
		do
			$versionApp ./stamp/tinystm/ssca2/ssca2 -s20 -i1.0 -u1.0 -l3 -p3 -t${i} >> tempUn.txt 
		done	
			dataProcess
			stats
		
		for ((j=1; j<=$testQtd; j++))
		do
			$versionApp ./stamp/tinystm/vacation/vacation -n2 -q90 -u98 -r1048576 -T4194304 -L -t${i} >> tempUn.txt  #low contention
		done	
			dataProcess
			stats
		
		for ((j=1; j<=$testQtd; j++))
		do
			$versionApp ./stamp/tinystm/vacation/vacation -n4 -q60 -u90 -r1048576 -T4194304 -t${i} >> tempUn.txt  #high contention
		done	
			dataProcess
			stats
		
		for ((j=1; j<=$testQtd; j++))
		do
			$versionApp ./stamp/tinystm/yada/yada -a15 -i stamp/data/yada/inputs/ttimeu1000000.2 -t${i} >> tempUn.txt 
		done	
			dataProcess
			stats
		

		if [ $i -eq 1 ]
		then
			i=0
		fi
	done
}

function dataProcess(){
	grep -f filtro.txt tempUn.txt > timeDataFull.txt
	./timeDataEdit.sh >> timeData.txt #ver como inserir neste msm arquivo
	rm timeDataFull.txt
	sed -e 's/.*=//' -e 's/  */ /g' timeData.txt > timeDataTemp.txt
	rm timeData.txt
}

function stats(){
	array=()
	standardDeviation=()

	readarray -t array < timeDataTemp.txt
	sum=$(dc -e "0 ${array[*]/-/_} ${array[*]/*/+} p")
	media=$(echo "scale=10; $sum / 10" | bc -l)
	standardDeviation=$(
		echo "${array[*]}" | 
			awk '{
				sum=0;ssq=0;
				for(i=1; i<=10; i++){
					sum+=$i;
					ssq+=($i*$i);
				}
				print 2*(sqrt(ssq/10-(sum/10)*(sum/10)))
			}'		
		)
	echo ""$media" "$standardDeviation" "$i" "$version"" >> temp.txt
	rm timeDataTemp.txt
	rm tempUn.txt
}

currDir=$(echo $(pwd))
currTSTM="${currDir}/tinystmBiblio"
echo $currTSTM

(cd stamp/trunk && make -B TMBUILD=tinystm TMLIBDIR=$currTSTM)

testQtd=10

threadsConfig

for version in {0..2}
do
	if [ $version -eq 0 ]
	then
		versionApp=()
	fi
	if [ $version -eq 1 ]
	then
		versionApp="numactl --interleave=all" #round robin = scatter
	fi
	if [ $version -eq 2 ]
	then
		lscpuInfo
		versionApp="numactl --cpubind=$nodesInUse --membind=$nodesInUse" #"close"
	fi

	benchConfig
done

mkdir Graphs
python3 plot.py