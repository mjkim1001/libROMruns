#!/bin/bash
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
myPath=./dependencies/libROM/libROMruns/HRC/2502/tp/
source ./clean_run.sh
for t in 0.8; do
for k in 2 3; do
for s in 7 4; do
kk=$((k - 1))
output="${myPath}/tpEQPwin${t}s${s}ok${k}.txt"
fractions=(0.99 0.999 0.9999 0.99999 0.999999 0.9999999)
printf "method,solver,window,w,t,ef,k,ErrX,ErrV,ErrE,TT2,nqp\n"  > "$output"
rm -r ./run/
laghos -m data/box01_hex.mesh -p 3 -ok ${k} -ot ${kk} -cfl 0.05 -rs 1 -pa -s $s -tf $t -offline -romsns -rpar 0 -sample-stages -rostype interpolate -sdim 100000 -writesol > "${myPath}/tp_eqp_offline${t}ws${ws}n${n}k${k}.txt"
for n in 0  2 ; do
for ww in 2;do
if [ $s -eq 4 ]; then
  ws=80
elif [ $s -eq 7 ]; then
  ws=40
fi
if [ $k -eq 3 ]; then 
ws=$((ws+40))
fi
printf "${ws}"
clean_run_offline
merge -nset 1 -romsns -romos -rostype interpolate -nwinsamp ${ws} -ef ${fractions[$n]} -eqp > "${myPath}/tp_eqp_merge${t}ws${ws}n${n}k${k}.txt"
w=$(find ./run -name 'basisE*' | wc -l)
printf "EQPglobal,${s},${ws},${w},${t},${fractions[$n]},${k}" >> "$output"
laghos -m data/box01_hex.mesh -p 3 -ok ${k} -ot ${kk} -cfl 0.05 -rs 1 -pa -s $s -tf $t -online -romhrprep -romsns -nwin $w -rostype interpolate -hrsamptype eqp -lqnnls > "${myPath}/tp_eqp_prep${t}ws${ws}n${n}k${k}.txt"
srun -n 1 -p pdebug laghos -m data/box01_hex.mesh -p 3 -ok ${k} -ot ${kk} -cfl 0.05 -rs 1 -pa -s $s -tf $t -online -romhr -romsns -nwin $w -rostype interpolate -hrsamptype eqp -lqnnls > "${myPath}/tp_eqp_online${t}ws${ws}n${n}k${k}.txt"
srun -n 1 -p pdebug laghos -m data/box01_hex.mesh -ok ${k} -ot ${kk} -cfl 0.05 -rs 1 -pa -restore -s $s -tf $t -romsns -soldiff -rostype interpolate -nwin $w > "${myPath}/tp_eqp_restore${t}ws${ws}n${n}k${k}.txt"
nt=$(($(find ./run/ROMsol -name 'romS*' | wc -l)-1))
errX=$(cat ${myPath}/tp_eqp_restore${t}ws${ws}n${n}k${k}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/tp_eqp_restore${t}ws${ws}n${n}k${k}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/tp_eqp_restore${t}ws${ws}n${n}k${k}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT2=$(cat ${myPath}/tp_eqp_online${t}ws${ws}n${n}k${k}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/tp_eqp_prep${t}ws${ws}n${n}k${k}.txt |  grep 'Global number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*' | tr '\n' ',')
printf ",,${errX},${errV},${errE},${TT2},${nqp}${nt}\n" >> "$output"
done
if [ $s -eq 4 ]; then
  ws=80
elif [ $s -eq 7 ]; then
  ws=40
fi
if [ $k -eq 3 ]; then
ws=$((ws+40))
fi
#rm -r ./run/
#laghos -m data/box01_hex.mesh -p 3 -ok ${k} -ot ${kk} -cfl 0.05 -rs 1 -pa -s $s -tf $t -offline -romsns -rpar 0 -sample-stages -rostype interpolate -sdim 100000 -writesol > "${myPath}/tp_eqp_offline${t}ws${ws}n${n}k${k}.txt"
#merge -nset 1 -romsns -romos -rostype interpolate -nwinsamp ${ws} -ef ${fractions[$n]} -eqp > "${myPath}/tp_eqp_merge${t}ws${ws}n${n}k${k}${q}.txt"
w=$(find ./run -name 'basisE*' | wc -l)
for((qq=1;qq<=10;qq++)) do
q=$((qq*20))
printf "EQP,${s},${ws},${w},${t},${fractions[$n]},${k}" >> "$output"
clean_run_merge
laghos -m data/box01_hex.mesh -p 3 -ok ${k} -ot ${kk} -cfl 0.05 -rs 1 -pa -s $s -tf $t -online -romhrprep -romsns -nwin $w -rostype interpolate -hrsamptype eqp -lqnnls -maxnnls $q > "${myPath}/tp_eqp_prep${t}ws${ws}n${n}k${k}${q}.txt"
srun -n 1 -p pdebug laghos -m data/box01_hex.mesh -p 3 -ok ${k} -ot ${kk} -cfl 0.05 -rs 1 -pa -s $s -tf $t -online -romhr -romsns -nwin $w -rostype interpolate -hrsamptype eqp -lqnnls > "${myPath}/tp_eqp_online${t}ws${ws}n${n}k${k}${q}.txt"
srun -n 1 -p pdebug laghos -m data/box01_hex.mesh -ok ${k} -ot ${kk} -cfl 0.05 -rs 1 -pa -restore -s $s -tf $t -romsns -soldiff -rostype interpolate -nwin $w > "${myPath}/tp_eqp_restore${t}ws${ws}n${n}k${k}${q}.txt"
nt=$(($(find ./run/ROMsol -name 'romS*' | wc -l)-1))
        errX=$(cat ${myPath}/tp_eqp_restore${t}ws${ws}n${n}k${k}${q}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errE=$(cat ${myPath}/tp_eqp_restore${t}ws${ws}n${n}k${k}${q}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errV=$(cat ${myPath}/tp_eqp_restore${t}ws${ws}n${n}k${k}${q}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT2=$(cat ${myPath}/tp_eqp_online${t}ws${ws}n${n}k${k}${q}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/tp_eqp_prep${t}ws${ws}n${n}k${k}${q}.txt |  grep 'Global number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*' | tr '\n' ',')
        printf ",${q},${errX},${errV},${errE},${TT2},${nqp}${nt}\n" >> "$output"
done
done
done
done done
