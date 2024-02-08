#!/bin/bash
#SBATCH -N 1
#SBATCH -t 23:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
myPath=./sbWin
for t in 0.1; do
for rs in 2;do
	output="${myPath}/sbWin${t}rerun.txt"
#printf "method,t,ws,nsr,TT1,TT3,TT4,ErrX,ErrV,ErrE\n"  > "$output"
for((ww=1 ;ww<=15;ww++)) do
ws=$((ww*5))
rm -r run/sbWin
srun -n 1 -p pdebug laghos -o sbWin -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs ${rs} -s 7 -offline -writesol -visit -romsvds -romos -rostype load -romsns -nwinsamp ${ws} -ef 0.9999 -sample-stages > ${myPath}/sb_offline${t}w${ww}.txt
TT1=$(cat ${myPath}/sb_offline${t}w${ww}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
w=$(find ./run/sbWin -name 'basisE*' | wc -l)
for ((q=2; q<= 2; ++q)) do
rm -r run/sbWinS
rsync -a run/sbWin/. run/sbWinS/
printf "q${q}ws${ws}sopt"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs ${rs} -s 7 -online -romhrprep  -romos -rostype load -nwin $w -romsvds  -romgs -romsns -sfacv $q -sface $q -hrsamptype sopt > "${myPath}/sb_sopt_hyper${t}q${q}ws${ws}rs${rs}.txt"
printf "online"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs ${rs} -s 7 -online -romhr -romsvds -romos -rostype load -nwin $w -romgs -romsns -sfacv $q -sface $q  > "${myPath}/sb_sopt_online${t}q${q}ws${ws}rs${rs}.txt"
printf "restore"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211  -tf $t -rs ${rs} -s 7 -restore -soldiff -romsvds  -romos -rostype load -nwin $w -romgs -romsns  > "${myPath}/sb_sopt_restore${t}q${q}ws${ws}rs${rs}.txt"
errX=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT3=$(cat ${myPath}/sb_sopt_online${t}q${q}ws${ws}rs${rs}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT4=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Total time: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_sopt_online${t}q${q}ws${ws}rs${rs}.txt | grep "solver nqp times nzones " | egrep -wo '[0-9]*'| tr '\n' ',' )
printf "sopt,${t},${ws},${q},${TT1},${TT3},${TT4},${errX},${errV},${errE}\n" >> "$output"

errX=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT3=$(cat ${myPath}/sb_qdeim_online${t}q${q}ws${ws}rs${rs}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT4=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Total time: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_qdeim_online${t}q${q}ws${ws}rs${rs}.txt | grep "solver nqp times nzones " | egrep -wo '[0-9]*'| tr '\n' ',' )
printf "qdeim,${t},${ws},${q},${TT1},${TT3},${TT4},${errX},${errV},${errE}\n" >> "$output"

errX=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT3=$(cat ${myPath}/sb_gnat_online${t}q${q}ws${ws}rs${rs}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT4=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Total time: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_gnat_online${t}q${q}ws${ws}rs${rs}.txt | grep "solver nqp times nzones " | egrep -wo '[0-9]*'| tr '\n' ',' )
printf "gnat,${t},${ws},${q},${TT1},${TT3},${TT4},${errX},${errV},${errE}\n" >> "$output"
done
done
done
done
