#!/bin/bash
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
myPath=./dependencies/libROM/libROMruns/HRC/sbNE
for t in 0.1; do
output="${myPath}/sbWin${t}.txt"
printf "method,t,ef,ws,w,q,nqp,TT3,ErrX,ErrV,ErrE\n"  > "$output"
fractions=(0.99 0.999 0.9999 0.99999 0.999999 0.9999999)
for n in 2 3 4 5; do
for((ww=1 ;ww<2;ww++)) do
ws=$((ww*20))
rm -r run/sbWin
srun -n 1 -p pdebug laghos -o sbWin -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs 2 -s 4 -bef 1.0 -offline -writesol -visit -romos -rostype load -romsns -nwinsamp ${ws} -sdim 1000000 -ef ${fractions[$n]} -sample-stages > ${myPath}/sb_offline${t}ws${ws}n${n}.txt
w=$(find ./run/sbWin -name 'basisE*' | wc -l)
for ((q=2; q<= 9; ++q)) do
rm -r run/sbWinS
rsync -a run/sbWin/. run/sbWinS/
printf "q${q}ws${ws}sopt"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs 2 -s 4 -bef 1.0 -online -romhrprep  -romos -rostype load -nwin $w  -romgs -romsns -sfacv $q -sface $q -hrsamptype sopt > "${myPath}/sb_sopt_hyper${t}q${q}ws${ws}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs 2 -s 4 -bef 1.0 -online -romhr -romos -rostype load -nwin $w -romgs -romsns -sfacv $q -sface $q  > "${myPath}/sb_sopt_online${t}q${q}ws${ws}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211  -tf $t -rs 2 -s 4 -bef 1.0 -restore -soldiff  -romos -rostype load -nwin $w -romgs -romsns  > "${myPath}/sb_sopt_restore${t}q${q}ws${ws}n${n}.txt"
errX=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT2=$(cat ${myPath}/sb_sopt_hyper${t}q${q}ws${ws}n${n}.txt | grep "hyper-reduction preprocessing: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tr '\n' ',')
TT3=$(cat ${myPath}/sb_sopt_online${t}q${q}ws${ws}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT4=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}n${n}.txt | grep "Total time: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_sopt_online${t}q${q}ws${ws}n${n}.txt | grep "Total number of quadrature points " | egrep -wo '[0-9]*'| tr '\n' ',' )
printf "sopt,${t},${fractions[$n]},${ws},${w},${q},${nqp}${TT3},${errX},${errV},${errE}\n" >> "$output"

rm -r run/sbWinS
rsync -a run/sbWin/. run/sbWinS/
printf "q${q}ws${ws}qdeim"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs 2 -s 4 -bef 1.0 -online -romhrprep  -romos -rostype load -nwin $w  -romgs -romsns -sfacv $q -sface $q -hrsamptype qdeim > "${myPath}/sb_qdeim_hyper${t}q${q}ws${ws}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs 2 -s 4 -bef 1.0 -online -romhr -romos -rostype load -nwin $w -romgs -romsns -sfacv $q -sface $q  > "${myPath}/sb_qdeim_online${t}q${q}ws${ws}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211  -tf $t -rs 2 -s 4 -bef 1.0 -restore -soldiff  -romos -rostype load -nwin $w -romgs -romsns  > "${myPath}/sb_qdeim_restore${t}q${q}ws${ws}n${n}.txt"
errX=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT2=$(cat ${myPath}/sb_qdeim_hyper${t}q${q}ws${ws}n${n}.txt | grep "hyper-reduction preprocessing: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tr '\n' ',')
TT3=$(cat ${myPath}/sb_qdeim_online${t}q${q}ws${ws}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT4=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}n${n}.txt | grep "Total time: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_qdeim_online${t}q${q}ws${ws}n${n}.txt | grep "Total number of quadrature points " | egrep -wo '[0-9]*'| tr '\n' ',' )
printf "qdeim,${t},${fractions[$n]},${ws},${w},${q},${nqp}${TT3},${errX},${errV},${errE}\n" >> "$output"

rm -r run/sbWinS
rsync -a run/sbWin/. run/sbWinS/
printf "q${q}ws${ws}gnat"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs 2 -s 4 -bef 1.0 -online -romhrprep  -romos -rostype load -nwin $w  -romgs -romsns -sfacv $q -sface $q -hrsamptype gnat > "${myPath}/sb_gnat_hyper${t}q${q}ws${ws}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -rs 2 -s 4 -bef 1.0 -online -romhr -romos -rostype load -nwin $w -romgs -romsns -sfacv $q -sface $q  > "${myPath}/sb_gnat_online${t}q${q}ws${ws}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbWinS -p 1 -m data/cube01_hex.mesh -pt 211  -tf $t -rs 2 -s 4 -bef 1.0 -restore -soldiff  -romos -rostype load -nwin $w -romgs -romsns  > "${myPath}/sb_gnat_restore${t}q${q}ws${ws}n${n}.txt"
errX=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT2=$(cat ${myPath}/sb_gnat_hyper${t}q${q}ws${ws}n${n}.txt | grep "hyper-reduction preprocessing: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tr '\n' ',')
TT3=$(cat ${myPath}/sb_gnat_online${t}q${q}ws${ws}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT4=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}n${n}.txt | grep "Total time: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_gnat_online${t}q${q}ws${ws}n${n}.txt | grep "Total number of quadrature points " | egrep -wo '[0-9]*'| tr '\n' ',' )
printf "gnat,${t},${fractions[$n]},${ws},${w},${q},${nqp}${TT3},${errX},${errV},${errE}\n" >> "$output"
done
done
done
done
