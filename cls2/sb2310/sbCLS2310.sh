#!/bin/bash
#SBATCH -N 1
#SBATCH -t 10:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
for t in 0.05; do
myPath=dependencies/libROM/libROMruns/cls/sb2310
output="${myPath}/sbCLSt${t}.txt"
printf "method,t,xx,vv,ee,q,condV,condE,time,ErrX,ErrV,ErrE\n"  > "$output"
fractions=(0.99 0.999 0.9999 0.99999 0.999999 0.9999999)
for ((n = 0; n < "${#fractions[@]}"; n++)); do

rm -r run/sbShort
srun -n 1 -p pdebug laghos -o sbShort -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -offline -romsns -writesol -visit -romsvds -sdim 1000 -ef ${fractions[$n]} -sample-stages > "${myPath}/sbcls_offlinet${t}n${n}.txt"
ndim=($(grep "Take first" ${myPath}/sbcls_offlinet${t}n${n}.txt | awk '{print $3}'))
echo $ndim

for((qq=1 ;qq<=10;qq++)) do
q=$((qq*10))

rm -r run/sbShortSerial
rsync -a run/sbShort/. run/sbShortSerial/
printf "cls q${q}sopt" 
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q -hrsamptype sopt > "${myPath}/sbcls_sopt_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q  > "${myPath}/sbcls_sopt_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -restore -precls -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/sbcls_sopt_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/sbcls_sopt_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sbcls_sopt_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sbcls_sopt_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/sbcls_sopt_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/sbcls_sopt_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
echo $cond

printf "clssopt,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"
rm -r run/sbShortSerial
rsync -a run/sbShort/. run/sbShortSerial/
printf "cls q${q}qdeim" 
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q -hrsamptype qdeim > "${myPath}/sbcls_qdeim_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q > "${myPath}/sbcls_qdeim_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -restore -precls -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/sbcls_qdeim_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/sbcls_qdeim_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sbcls_qdeim_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sbcls_qdeim_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/sbcls_qdeim_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/sbcls_qdeim_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "clsqdeim,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

rm -r run/sbShortSerial
rsync -a run/sbShort/. run/sbShortSerial/
printf "cls q${q}gnat" 
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q -hrsamptype gnat > "${myPath}/sbcls_gnat_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q > "${myPath}/sbcls_gnat_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -restore -precls -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/sbcls_gnat_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/sbcls_gnat_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sbcls_gnat_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sbcls_gnat_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/sbcls_gnat_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/sbcls_gnat_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "clsgnat,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

rm -r run/sbShortSerial
rsync -a run/sbShort/. run/sbShortSerial/
printf "q${q}sopt" 
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q -hrsamptype sopt > "${myPath}/sb_sopt_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q  > "${myPath}/sb_sopt_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -restore -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/sb_sopt_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/sb_sopt_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_sopt_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_sopt_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/sb_sopt_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/sb_sopt_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
echo $cond

printf "sopt,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"
rm -r run/sbShortSerial
rsync -a run/sbShort/. run/sbShortSerial/
printf "q${q}qdeim"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q -hrsamptype qdeim > "${myPath}/sb_qdeim_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q > "${myPath}/sb_qdeim_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -restore -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/sb_qdeim_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/sb_qdeim_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_qdeim_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_qdeim_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/sb_qdeim_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/sb_qdeim_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "qdeim,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

rm -r run/sbShortSerial
rsync -a run/sbShort/. run/sbShortSerial/
printf "q${q}gnat"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q -hrsamptype gnat > "${myPath}/sb_gnat_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q > "${myPath}/sb_gnat_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o sbShortSerial -p 1 -m data/cube01_hex.mesh -pt 211 -tf $t -s 7 -restore -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/sb_gnat_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/sb_gnat_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_gnat_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_gnat_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/sb_gnat_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/sb_gnat_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "gnat,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

done
done
done
