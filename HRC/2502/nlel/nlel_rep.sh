#!/bin/bash
#SBATCH -N 1
#SBATCH -t 3:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
source _get_vecs.sh
myPath=../../../libROMruns/HRC/2502/nlel
for t in 1.0;do
output="${myPath}/nlel_xv_rep${t}.txt"
#printf "method,t,energy_frac,rxdim,rvdim,nldim,q,nqp,time,err_x,err_v\n"  > "$output"
# Declare energy fraction array
fractions=(0.9 0.99 0.999 0.9999 0.99999 0.999999 0.9999999)
rm basis* 
# X and V basis, repictive test
dt=0.01
nonlinear_elasticity_global_rom -offline -dt ${dt} -tf $t -s 14 -vs 100 > "${myPath}/nlel_offline1.txt"
nonlinear_elasticity_global_rom -merge -ns 1 -dt ${dt} -tf $t > "${myPath}/nlel_merge.txt"
# Read the text file containing energy fractions and basis vectors
x_name="mergedSV_X.txt"
IFS=" " read -r -a n_x <<<"$(get_vectors $x_name)"
v_name="mergedSV_V.txt"
IFS=" " read -r -a n_v <<<"$(get_vectors $v_name)"
nl_name="mergedSV_H.txt"
IFS=" " read -r -a n_nl <<<"$(get_vectors $nl_name)"
echo "Recovering number of basis vectors:"
for n in 0 1 2 3 4 5;do
#for ((n = 6; n <= "${#fractions[@]}"; n++)); do
    	echo "frac: ${fractions[$n]}, x-basis vectors: ${n_x[$n]}, v-basis vectors: ${n_v[$n]}, nl-basis vectors: ${n_nl[$n]}"
   srun -n 1 -p pdebug nonlinear_elasticity_global_rom -online -rxdim ${n_x[$n]} -rvdim ${n_v[$n]} -dt ${dt} -tf $t -eqp -ns 1 -sc 1.0 -hdim 1 >"${myPath}/nlel_eqp_rep_online${n}q${q}.txt"
        err_x=$(cat ${myPath}/nlel_eqp_rep_online${n}q${q}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        err_v=$(cat ${myPath}/nlel_eqp_rep_online${n}q${q}.txt | grep "Relative error of ROM velocity (v) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_eqp_rep_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_eqp_rep_online${n}q${q}.txt |  grep 'Global number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*')
m_value=$(awk -F'[,=]' '/NNLS solver:/ {gsub(/ /, "", $2); print $2}' ${myPath}/nlel_eqp_rep_online${n}q${q}.txt)
n_value=$(awk -F'[,=]' '/NNLS solver:/ {gsub(/ /, "", $4); print $4}' ${myPath}/nlel_eqp_rep_online${n}q${q}.txt)
	printf "EQPGlobal,${t},${fractions[$n]},${n_x[$n]},${n_v[$n]},${m_value},${n_value},${nqp},${TT},${err_x},${err_v}\n" >> "$output"
for((qq=1 ;qq<=25;qq++)) do
if (( qq >= 1 && qq <= 4 )); then
    q=$((50 * qq))
else
    q=$((200 * (qq - 3)))
fi
srun -n 1 -p pdebug nonlinear_elasticity_global_rom -online -rxdim ${n_x[$n]} -rvdim ${n_v[$n]} -dt ${dt} -tf $t -eqp -ns 1 -sc 1.0 -maxnnls $q -hdim 1 >"${myPath}/nlel_eqp_rep_online${n}q${q}.txt"
        err_x=$(cat ${myPath}/nlel_eqp_rep_online${n}q${q}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        err_v=$(cat ${myPath}/nlel_eqp_rep_online${n}q${q}.txt | grep "Relative error of ROM velocity (v) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_eqp_rep_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_eqp_rep_online${n}q${q}.txt |  grep 'Global number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*')
m_value=$(awk -F'[,=]' '/NNLS solver:/ {gsub(/ /, "", $2); print $2}' ${myPath}/nlel_eqp_rep_online${n}q${q}.txt)
n_value=$(awk -F'[,=]' '/NNLS solver:/ {gsub(/ /, "", $4); print $4}' ${myPath}/nlel_eqp_rep_online${n}q${q}.txt)
        printf "EQP,${t},${fractions[$n]},${n_x[$n]},${n_v[$n]},${n_value},${q},${nqp},${TT},${err_x},${err_v}\n" >> "$output"
done
for((qq=1 ;qq<=15;qq++)) do
if (( qq >= 1 && qq <= 5 )); then
    q=$((20 * qq))
else
    q=$((100 * (qq - 4)))
fi
	#q=$((${n_nl[$n]}*2))
       srun -n 1 -p pdebug nonlinear_elasticity_global_rom -online -dt ${dt} -tf $t -s 14 -hyp -hrtype sopt -rvdim ${n_v[$n]} -rxdim ${n_x[$n]}  -hdim ${n_nl[$n]} -sc 1.0 -nsr $q > "${myPath}/nlel_sopt_rep_online${n}q${q}.txt"
        err_x=$(cat ${myPath}/nlel_sopt_rep_online${n}q${q}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        err_v=$(cat ${myPath}/nlel_sopt_rep_online${n}q${q}.txt | grep "Relative error of ROM velocity (v) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_sopt_rep_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_sopt_rep_online${n}q${q}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "SOPT,${t},${fractions[$n]},${n_x[$n]},${n_v[$n]},${n_nl[$n]},${q},$((nqp*9)),${TT},${err_x},${err_v}\n" >> "$output"

     srun -n 1 -p pdebug nonlinear_elasticity_global_rom -online -dt ${dt} -tf $t -s 14 -hyp -hrtype gnat -rvdim ${n_v[$n]} -rxdim ${n_x[$n]}  -hdim ${n_nl[$n]} -sc 1.0 -nsr $q > "${myPath}/nlel_pod_rep_online${n}q${q}.txt"
        err_x=$(cat ${myPath}/nlel_pod_rep_online${n}q${q}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        err_v=$(cat ${myPath}/nlel_pod_rep_online${n}q${q}.txt | grep "Relative error of ROM velocity (v) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_pod_rep_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_pod_rep_online${n}q${q}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "gappy-POD,${t},${fractions[$n]},${n_x[$n]},${n_v[$n]},${n_nl[$n]},${q},$((nqp*9)),${TT},${err_x},${err_v}\n" >> "$output"

      srun -n 1 -p pdebug nonlinear_elasticity_global_rom -online -dt ${dt} -tf $t -s 14 -hyp -hrtype qdeim -rvdim ${n_v[$n]} -rxdim ${n_x[$n]}  -hdim ${n_nl[$n]} -sc 1.0 -nsr $q > "${myPath}/nlel_qdeim_rep_online${n}q${q}.txt"
        err=$(cat ${myPath}/nlel_qdeim_rep_online${n}q${q}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_qdeim_rep_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_qdeim_rep_online${n}q${q}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "QDEIM,${t},${fractions[$n]},${n_x[$n]},${n_v[$n]},${n_nl[$n]},${q},$((nqp*9)),${TT},${err_x},${err_v}\n" >> "$output"
done
done
done
