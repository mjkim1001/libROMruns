#!/bin/bash
#SBATCH -N 1
#SBATCH -t 10:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
for t in 0.05; do
myPath=dependencies/libROM/libROMruns/cls/gv2310
output="${myPath}/gvCLSt${t}.txt"
printf "method,t,xx,vv,ee,q,condV,condE,time,ErrX,ErrV,ErrE\n"  > "$output"
fractions=(0.9 0.99 0.999 0.9999 0.99999 0.999999 0.9999999)
for ((n = 1; n < "${#fractions[@]}"; n++)); do

rm -r run/gvShort
srun -n 1 -p pdebug laghos -o gvShort -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -offline -romsns -writesol -visit -romsvds -sdim 1000 -ef ${fractions[$n]} -sample-stages > "${myPath}/gvcls_offlinet${t}n${n}.txt"
ndim=($(grep "Take first" ${myPath}/gvcls_offlinet${t}n${n}.txt | awk '{print $3}'))
echo $ndim

for((qq=1 ;qq<=20;qq++)) do
q=$((qq*10))

rm -r run/gvShortSerial
rsync -a run/gvShort/. run/gvShortSerial/
printf "cls q${q}sopt" 
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q -hrsamptype sopt > "${myPath}/gvcls_sopt_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q  > "${myPath}/gvcls_sopt_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -restore -precls -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/gvcls_sopt_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/gvcls_sopt_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/gvcls_sopt_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/gvcls_sopt_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/gvcls_sopt_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/gvcls_sopt_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
echo $cond

printf "clssopt,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"
rm -r run/gvShortSerial
rsync -a run/gvShort/. run/gvShortSerial/
printf "cls q${q}qdeim" 
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q -hrsamptype qdeim > "${myPath}/gvcls_qdeim_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q > "${myPath}/gvcls_qdeim_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -restore -precls -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/gvcls_qdeim_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/gvcls_qdeim_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/gvcls_qdeim_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/gvcls_qdeim_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/gvcls_qdeim_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/gvcls_qdeim_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "clsqdeim,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

rm -r run/gvShortSerial
rsync -a run/gvShort/. run/gvShortSerial/
printf "cls q${q}gnat" 
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q -hrsamptype gnat > "${myPath}/gvcls_gnat_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -precls -sfacv $q -sface $q > "${myPath}/gvcls_gnat_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -restore -precls -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/gvcls_gnat_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/gvcls_gnat_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/gvcls_gnat_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/gvcls_gnat_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/gvcls_gnat_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/gvcls_gnat_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "clsgnat,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

rm -r run/gvShortSerial
rsync -a run/gvShort/. run/gvShortSerial/
printf "q${q}sopt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q -hrsamptype sopt > "${myPath}/gv_sopt_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q  > "${myPath}/gv_sopt_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -restore -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/gv_sopt_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/gv_sopt_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/gv_sopt_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/gv_sopt_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/gv_sopt_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/gv_sopt_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
echo $cond

printf "sopt,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"
rm -r run/gvShortSerial
rsync -a run/gvShort/. run/gvShortSerial/
printf "q${q}qdeim"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q -hrsamptype qdeim > "${myPath}/gv_qdeim_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q > "${myPath}/gv_qdeim_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -restore -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/gv_qdeim_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/gv_qdeim_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/gv_qdeim_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/gv_qdeim_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/gv_qdeim_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/gv_qdeim_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "qdeim,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

rm -r run/gvShortSerial
rsync -a run/gvShort/. run/gvShortSerial/
printf "q${q}gnat"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhrprep -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q -hrsamptype gnat > "${myPath}/gv_gnat_hyper${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -online -romhr -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]} -sfacv $q -sface $q > "${myPath}/gv_gnat_online${t}q${q}n${n}.txt"
srun -n 1 -p pdebug laghos -o gvShortSerial -p 4 -m data/square_gresho.mesh -rs 4 -ok 3 -ot 2 -tf $t -s 7 -restore -soldiff -romsvds -romsns -rdimx ${ndim[0]} -rdime ${ndim[1]} -rdimv ${ndim[2]}  > "${myPath}/gv_gnat_restore${t}q${q}n${n}.txt"
errX=$(cat ${myPath}/gv_gnat_restore${t}q${q}n${n}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/gv_gnat_restore${t}q${q}n${n}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/gv_gnat_restore${t}q${q}n${n}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT=$(cat ${myPath}/gv_gnat_online${t}q${q}n${n}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
cond=$(grep "conditionNum:" ${myPath}/gv_gnat_hyper${t}q${q}n${n}.txt | awk -F: '{print $2}' | awk '{print $1}' | paste -sd "," -)
printf "gnat,${t},${ndim[0]},${ndim[1]},${ndim[2]},${q},${cond},${TT},${errX},${errV},${errE}\n" >> "$output"

done
done
done
