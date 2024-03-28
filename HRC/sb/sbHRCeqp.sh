#!/bin/bash
#SBATCH -N 1
#SBATCH -t 23:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
myPath=./dependencies/libROM/libROMruns/HRC/sb/
for t in 0.1; do
output="${myPath}/sbEQPwin${t}ef.txt"
#printf "method,window,w,t,q,ErrX,ErrV,ErrE,TT2,nqp\n"  > "$output"
fractions=(0.99 0.999 0.9999 0.99999 0.999999 0.9999999)
for n in 3 1 4 ; do
for((ww=1 ;ww<2;ww++)) do
ws=$((ww*20))
break
printf "${ws}"
rm -r ./run/
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -bef 1.0 -offline -romsns -rpar 0 -sample-stages -rostype interpolate -sdim 100000 -ef ${fractions[$n]} -writesol > "${myPath}/sb_eqp_offline${t}ws${ws}n${n}.txt"
srun -n 1 -p pdebug merge -nset 1 -romsns -romos -rostype interpolate -nwinsamp ${ws}  -ef ${fractions[$n]} -eqp -nwinover 4  > "${myPath}/sb_eqp_merge${t}ws${ws}n${n}.txt"
w=$(find ./run -name 'basisE*' | wc -l)
printf "EQPglobal,${ws},${w},${t},${fractions[$n]}" >> "$output"
laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -online -romhrprep -romsns -bef 1.0 -nwin $w -rostype interpolate -hrsamptype eqp > "${myPath}/sb_eqp_prep${t}ws${ws}n${n}.txt"
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -online -romhr -romsns -bef 1.0 -nwin $w -rostype interpolate -hrsamptype eqp > "${myPath}/sb_eqp_online${t}ws${ws}n${n}.txt"
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -restore -romsns -soldiff -rostype interpolate -hrsamptype eqp -nwin $w -tf $t > "${myPath}/sb_eqp_restore${t}ws${ws}n${n}.txt"

        errX=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errE=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errV=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT2=$(cat ${myPath}/sb_eqp_online${t}ws${ws}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_eqp_prep${t}ws${ws}n${n}.txt |  grep 'Global number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*' | tr '\n' ',')
        printf ",,${errX},${errV},${errE},${TT2},${nqp}\n" >> "$output"
done

for((ww=1 ;ww<2;ww++)) do
ws=$((ww*20))
for((qq=10;qq<=10;qq++)) do
q=$((qq*20+20))
rm -r ./run/
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -bef 1.0 -offline -romsns -rpar 0 -sample-stages -rostype interpolate -sdim 100000 -ef ${fractions[$n]} -writesol > "${myPath}/sb_eqp_offline${t}ws${ws}n${n}.txt"
srun -n 1 -p pdebug merge -nset 1 -romsns -romos -rostype interpolate -nwinsamp ${ws}  -ef ${fractions[$n]} -eqp -nwinover 4  > "${myPath}/sb_eqp_merge${t}ws${ws}n${n}${q}.txt"
w=$(find ./run -name 'basisE*' | wc -l)
printf "EQP,${ws},${w},${t},${fractions[$n]}" >> "$output"
laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -online -romhrprep -romsns -bef 1.0 -nwin $w -rostype interpolate -hrsamptype eqp -maxnnls $q > "${myPath}/sb_eqp_prep${t}ws${ws}n${n}${q}.txt"
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -p 1 -s 4 -tf $t -online -romhr -romsns -bef 1.0 -nwin $w -rostype interpolate -hrsamptype eqp > "${myPath}/sb_eqp_online${t}ws${ws}n${n}${q}.txt"
srun -n 1 -p pdebug laghos -m data/cube01_hex.mesh -pt 211 -restore -romsns -soldiff -rostype interpolate -hrsamptype eqp -nwin $w -tf $t > "${myPath}/sb_eqp_restore${t}ws${ws}n${n}${q}.txt"

        errX=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}n${n}${q}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errE=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}n${n}${q}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        errV=$(cat ${myPath}/sb_eqp_restore${t}ws${ws}n${n}${q}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT2=$(cat ${myPath}/sb_eqp_online${t}ws${ws}n${n}${q}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_eqp_prep${t}ws${ws}n${n}${q}.txt |  grep 'Global number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*' | tr '\n' ',')

        printf ",${q},${errX},${errV},${errE},${TT2},${nqp}\n" >> "$output"
done
done
done
done
