#!/bin/bash
#SBATCH -N 1
#SBATCH -t 1:00:00
#SBATCH -p pdebug
#SBATCH --open-mode truncate
source _get_vecs.sh
myPath=../../../runnl0904
output="${myPath}/nlel_xv_pred_base5.txt"
printf "Method,dt,ef,rxdim,rvdim,ntw,q,time,errx,errv\n"  > "$output"
# Declare energy fraction array
fractions=(0.9 0.99 0.999 0.9999 0.99999 0.999999 0.9999999)
rm basis* 
# X and V basis, predictive test
for t in 5;do
dt=0.01
nonlinear_elasticity_global_rom -offline -dt ${dt} -tf $t -s 14 -vs 100 -sc 0.9 -id 0 > "${myPath}/nlel_offline1.txt"
nonlinear_elasticity_global_rom -offline -dt ${dt} -tf $t -s 14 -vs 100 -sc 1.1 -id 1 > "${myPath}/nlel_offline2.txt"
nonlinear_elasticity_global_rom -merge -ns 2 -dt ${dt} -tf $t > "${myPath}/nlel_merge.txt"
nonlinear_elasticity_global_rom -offline -dt ${dt} -tf $t -s 14 -vs 100 -sc 1.0 -id 2 > "${myPath}/nlel_offline3.txt"

# Read the text file containing energy fractions and basis vectors
x_name="mergedSV_X.txt"
IFS=" " read -r -a n_x <<<"$(get_vectors $x_name)"
v_name="mergedSV_V.txt"
IFS=" " read -r -a n_v <<<"$(get_vectors $v_name)"
nl_name="mergedSV_H.txt"
IFS=" " read -r -a n_nl <<<"$(get_vectors $nl_name)"
echo "Recovering number of basis vectors:"
for ntw in 500 200 ;do
for ((n = 0; n < "${#fractions[@]}"; n++)); do
    echo "frac: ${fractions[$n]}, x-basis vectors: ${n_x[$n]}, v-basis vectors: ${n_v[$n]}, nl-basis vectors: ${n_nl[$n]}"
   srun -n 1 -p pdebug nonlinear_elasticity_global_rom -online -rxdim ${n_x[$n]} -rvdim ${n_v[$n]} -dt ${dt} -tf $t -eqp -ns 2 -sc 1.0 -hdim ${n_nl[$n]} -ntw ${ntw} >"${myPath}/nlel_eqp_online${n}tw${ntw}.txt"
        err_x=$(cat ${myPath}/nlel_eqp_online${n}tw${ntw}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        err_v=$(cat ${myPath}/nlel_eqp_online${n}tw${ntw}.txt | grep "Relative error of ROM velocity (v) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_eqp_online${n}tw${ntw}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_eqp_online${n}tw${ntw}.txt |  grep 'Global number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*')
        printf "EQP,${dt},${fractions[$n]},${n_x[$n]},${n_v[$n]},${ntw},,${TT},${err_x},${err_v}\n" >> "$output"
continue # If you only want to run EQP results

q=$((${n_nl[$n]}*2))
        nonlinear_elasticity_global_rom -online -dt ${dt} -tf $t -s 14 -hyp -rvdim ${n_v[$n]} -rxdim ${n_x[$n]}  -hdim ${n_nl[$n]}  -nsr $q -sc 1.0 -sopt > "${myPath}/nlel_sopt_online${n}tw${ntw}.txt"
        err_x=$(cat ${myPath}/nlel_sopt_online${n}tw${ntw}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        err_v=$(cat ${myPath}/nlel_sopt_online${n}tw${ntw}.txt | grep "Relative error of ROM velocity (v) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_sopt_online${n}tw${ntw}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_sopt_online${n}tw${ntw}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "SOPT,${dt},${fractions[$n]},${n_x[$n]},${n_v[$n]},${n_nl[$n]},${q},$((nqp*9)),${TT},${err_x},${err_v}\n" >> "$output"

        nonlinear_elasticity_global_rom -online -dt ${dt} -tf $t -s 14 -hyp -rvdim ${n_v[$n]} -rxdim ${n_x[$n]}  -hdim ${n_nl[$n]}  -nsr $q -sc 1.0 > "${myPath}/nlel_pod_online${n}tw${ntw}.txt"
        err_x=$(cat ${myPath}/nlel_pod_online${n}tw${ntw}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        err_v=$(cat ${myPath}/nlel_pod_online${n}tw${ntw}.txt | grep "Relative error of ROM velocity (v) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_pod_online${n}tw${ntw}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_pod_online${n}tw${ntw}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "gappy-POD,${dt},${fractions[$n]},${n_x[$n]},${n_v[$n]},${n_nl[$n]},${q},$((nqp*9)),${TT},${err_x},${err_v}\n" >> "$output"

        nonlinear_elasticity_global_rom -online -dt ${dt} -tf $t -s 14 -hyp -rvdim ${n_v[$n]} -rxdim ${n_x[$n]}  -hdim ${n_nl[$n]}  -nsr $q -sc 1.0 -qdeim > "${myPath}/nlel_qdeim_online${n}tw${ntw}.txt"
        err=$(cat ${myPath}/nlel_qdeim_online${n}tw${ntw}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_qdeim_online${n}tw${ntw}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_qdeim_online${n}tw${ntw}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "QDEIM,${dt},${fractions[$n]},${n_x[$n]},${n_v[$n]},${n_nl[$n]},${q},$((nqp*9)),${TT},${err_x},${err_v}\n" >> "$output"
done
done
done
