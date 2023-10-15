#!/bin/bash
#SBATCH -N 1
#SBATCH -t 10:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
for t in 0.1; do
myPath=dependencies/libROM/libROMruns/cls/tg2310
output="${myPath}/tgCLS2t${t}.txt"
#printf "method,t,xx,vv,ee,q,condV,condE,time,ErrX,ErrV,ErrE\n"  > "$output"
fractions=(0.9 0.99 0.999 0.9999 0.99999 0.999999 0.9999999)
for ((n = 1; n < "${#fractions[@]}"; n++)); do

rm -r run/tgShort
srun -n 1 -p pdebug laghos -o tgShort -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -offline -romsns -writesol -visit -romsvds -sdim 1000 -ef ${fractions[$n]} -sample-stages > "${myPath}/tgcls_offlinet${t}n${n}.txt"
ndim=($(grep "Take first" ${myPath}/tgcls_offlinet${t}n${n}.txt | awk '{print $3}'))
echo $ndim

for((qq=1 ;qq<=20;qq++)) do
q=$((qq*10))

rm -r run/tgShortSerial
rsync -a run/tgShort/. run/tgShortSerial/
printf "cls q${q}sopt" 
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q -hrsamptype sopt > "${myPath}/tgcls_sopt_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q  > "${myPath}/tgcls_sopt_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -restore -precls -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/tgcls_sopt_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/tgcls_sopt_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/tgcls_sopt_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/tgcls_sopt_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/tgcls_sopt_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/tgcls_sopt_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
echo $cond

printf "clssopt,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"
rm -r run/tgShortSerial
rsync -a run/tgShort/. run/tgShortSerial/
printf "cls q${q}qdeim" 
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q -hrsamptype qdeim > "${myPath}/tgcls_qdeim_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q > "${myPath}/tgcls_qdeim_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -restore -precls -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/tgcls_qdeim_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/tgcls_qdeim_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/tgcls_qdeim_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/tgcls_qdeim_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/tgcls_qdeim_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/tgcls_qdeim_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "clsqdeim,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"
continue
rm -r run/tgShortSerial
rsync -a run/tgShort/. run/tgShortSerial/
printf "cls q${q}gnat" 
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q -hrsamptype gnat > "${myPath}/tgcls_gnat_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q > "${myPath}/tgcls_gnat_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -restore -precls -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/tgcls_gnat_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/tgcls_gnat_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/tgcls_gnat_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/tgcls_gnat_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/tgcls_gnat_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/tgcls_gnat_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "clsgnat,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

rm -r run/tgShortSerial
rsync -a run/tgShort/. run/tgShortSerial/
printf "q${q}sopt" 
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q -hrsamptype sopt > "${myPath}/tg_sopt_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q  > "${myPath}/tg_sopt_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -restore -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/tg_sopt_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/tg_sopt_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/tg_sopt_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/tg_sopt_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/tg_sopt_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/tg_sopt_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
echo $cond

printf "sopt,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"
rm -r run/tgShortSerial
rsync -a run/tgShort/. run/tgShortSerial/
printf "q${q}qdeim"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q -hrsamptype qdeim > "${myPath}/tg_qdeim_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q > "${myPath}/tg_qdeim_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -restore -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/tg_qdeim_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/tg_qdeim_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/tg_qdeim_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/tg_qdeim_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/tg_qdeim_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/tg_qdeim_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "qdeim,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

rm -r run/tgShortSerial
rsync -a run/tgShort/. run/tgShortSerial/
printf "q${q}gnat"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q -hrsamptype gnat > "${myPath}/tg_gnat_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q > "${myPath}/tg_gnat_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o tgShortSerial -p 0 -m data/cube01_hex.mesh -cfl 0.1 -tf $t -s 7 -restore -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/tg_gnat_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/tg_gnat_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/tg_gnat_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/tg_gnat_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/tg_gnat_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/tg_gnat_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "gnat,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

done
done
done
