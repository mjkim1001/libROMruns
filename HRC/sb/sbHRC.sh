#!/bin/bash
#SBATCH -N 1
#SBATCH -t 23:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
myPath=./dependencies/libROM/libROMruns/HRC/sb/
for t in 0.1; do
output="${myPath}/sbEQPwin${t}.txt"
printf "window,w,t,q,qV,qE,ErrX,ErrV,ErrE,TT1,TT2,TT3\n"  > "$output"
for((ww=2 ;ww<=20;ww++)) do
ws=$((ww*5))
printf "${ws}"
rm -r ./run/
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -bef 1.0 -offline -romsns -rpar 0 -sample-stages -rostype interpolate -sdim 1000 -writesol > "${myPath}/sb_eqp_offline${t}ws${ws}.txt"
srun -n 1 -p pdebug merge -nset 1 -romsns -romos -rostype interpolate -nwinsamp ${ws} -eqp -nwinover 4  > "${myPath}/sb_eqp_merge${t}ws${ws}.txt"
w=$(find ./run -name 'basisE*' | wc -l)
printf "${ws},${w},${t}" >> "$output"
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -online -romhrprep -romsns -bef 1.0 -nwin $w -rostype interpolate -hrsamptype eqp > "${myPath}/sb_eqp_prep${t}ws${ws}.txt"
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -online -romhr -romsns -bef 1.0 -nwin $w -rostype interpolate -hrsamptype eqp > "${myPath}/sb_eqp_online${t}ws${ws}.txt"
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -restore -romsns -soldiff -rostype interpolate -hrsamptype eqp -nwin $w -tf $t > "${myPath}/sb_eqp_restore${t}ws${ws}.txt"

        errX=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errE=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errV=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT1=$(cat ${myPath}/sb_eqp_merge${t}ws${ws}.txt | grep "Elapsed time for merge: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT2=$(cat ${myPath}/sb_eqp_prep${t}ws${ws}.txt | grep "Elapsed time for hyper-reduction preprocessing: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT3=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}.txt | grep "Total time: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')

        printf ",${errX},${errV},${errE},${TT1},${TT2},${TT3}\n" >> "$output"
done
done
