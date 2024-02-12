#!/bin/bash
#SBATCH -N 1
#SBATCH -t 23:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
myPath=./dependencies/libROM/libROMruns/HRC/sb/
for t in 0.1; do
for rs in 3;do
for ws in 40;do
output="${myPath}/sbEQPwin${t}rs${rs}.txt"
#printf "rs,window,w,t,ErrX,ErrV,ErrE,TT1,TT2,TT3\n"  > "$output"
#rm -r ./run/
#srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -rs ${rs} -bef 1.0 -offline -romsns -rpar 0 -sample-stages -rostype interpolate -sdim 10000 -writesol > "${myPath}/sb_eqp_offline${t}ws${ws}rs${rs}.txt"
#srun -n 1 -p pdebug merge -nset 1 -romsns -romos -rostype interpolate -nwinsamp ${ws} -eqp -nwinover 4  > "${myPath}/sb_eqp_merge${t}ws${ws}rs${rs}.txt"
w=$(find ./run -name 'basisE*' | wc -l)
printf "${rs},${ws},${w},${t}" >> "$output"
for((ww=3 ;ww < 4;ww++)) do
ss=$((ww*11))
ee=$((ss+10))
printf "${ee}"
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -rs ${rs} -online -romhrprep -romsns -bef 1.0 -nwin $w -rostype interpolate -hrsamptype eqp -nnlsw0 ${ss} -nnlsw1 ${ee} > "${myPath}/sb_eqp_prep${t}ws${ws}rs${rs}ss${ss}.txt"
done
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -rs ${rs} -online -romhr -romsns -bef 1.0 -nwin $w -rostype interpolate -hrsamptype eqp > "${myPath}/sb_eqp_online${t}ws${ws}rs${rs}.txt"
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -restore -romsns -soldiff -rostype interpolate -hrsamptype eqp -nwin $w -tf $t -rs ${rs} > "${myPath}/sb_eqp_restore${t}ws${ws}rs${rs}.txt"

        errX=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}rs${rs}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errE=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}rs${rs}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errV=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}rs${rs}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT1=$(cat ${myPath}/sb_eqp_merge${t}ws${ws}rs${rs}.txt | grep "Elapsed time for merge: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT2=$(cat ${myPath}/sb_eqp_online${t}ws${ws}rs${rs}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT3=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}rs${rs}.txt | grep "Total time: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')

        printf ",${errX},${errV},${errE},${TT1},${TT2},${TT3}\n" >> "$output"
done
done
done
