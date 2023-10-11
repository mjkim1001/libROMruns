#!/bin/bash
#SBATCH -N 1
#SBATCH -t 1:00:00
#SBATCH -p pdebug
#SBATCH --open-mode truncate
source _get_vecs.sh
myPath=../../../libROMruns/runnl1004
output="${myPath}/noscale_xv_rep_eqp.txt"
#printf "method,t,dt,rs,ef,rxdim,rvdim,nqp,nvar,m,n,time,errx,errv\n"  > "$output"
# Declare energy fraction array
fractions=(0.9 0.99 0.999 0.9999 0.99999 0.999999 0.9999999)
for t in 1.0; do # 2.0 3.0 4.0 5.0 6.0; do
for s in 2 ;do
	dt=0.01
while [ 1 ]; do
    rm basis*
    no_convergence_flag=0
    # Offline Phase 1
    nonlinear_elasticity_global_rom -offline -dt ${dt} -tf $t -s 14 -vs 100 -rs $s | tee "${myPath}/noscale_offline1rs${s}dt${dt}.txt" |
    while IFS= read -r line
    do
        if [[ $line == *"PCG: No convergence!"* ]]; then
            echo "No convergence detected in offline phase 1. Decreasing dt."
            dt=$(echo "$dt - 0.002" | bc)
            no_convergence_flag=1
            break
        fi
    done
    if [ $no_convergence_flag -eq 1 ]; then
        continue
    fi


    # Merge Phase
    merge_output=$(nonlinear_elasticity_global_rom -merge -ns 1 -dt ${dt} -tf $t  -rs $s )
    echo "$merge_output" > "${myPath}/noscale_merge${t}dt${dt}.txt"
    if [[ ! "$merge_output" =~ "Elapsed time for merging and building ROM basis:" ]]; then
        echo "Error detected in merge phase. Increasing dt."
        dt=$(echo "$dt + 0.002" | bc)
        continue
    fi

    #


# Read the text file containing energy fractions and basis vectors
x_name="mergedSV_X.txt"
IFS=" " read -r -a n_x <<<"$(get_vectors $x_name)"
v_name="mergedSV_V.txt"
IFS=" " read -r -a n_v <<<"$(get_vectors $v_name)"
nl_name="mergedSV_H.txt"
IFS=" " read -r -a n_nl <<<"$(get_vectors $nl_name)"

for ((n = 0; n < "${#fractions[@]}"; n++)); do
#for ((n = 6; n < 7 ; n++)); do
	echo "frac: ${fractions[$n]}, x-basis vectors: ${n_x[$n]}, v-basis vectors: ${n_v[$n]}, nl-basis vectors: ${n_nl[$n]}"
     nonlinear_elasticity_global_rom -online -rxdim ${n_x[$n]} -rvdim ${n_v[$n]} -dt ${dt} -tf $t -rs $s -eqp -ns 1 -hdim 1  > "${myPath}/noscale_eqp_online${n}rs${s}dt${dt}.txt"
        err_x=$(cat ${myPath}/noscale_eqp_online${n}rs${s}dt${dt}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        err_v=$(cat ${myPath}/noscale_eqp_online${n}rs${s}dt${dt}.txt | grep "Relative error of ROM velocity (v) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/noscale_eqp_online${n}rs${s}dt${dt}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/noscale_eqp_online${n}rs${s}dt${dt}.txt |  grep 'Global number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*')
  nvar=$(cat ${myPath}/noscale_eqp_online${n}rs${s}dt${dt}.txt |  grep 'Number of velocity/deformation unknowns: ' | egrep -wo '[0-9]*')
m_value=$(awk -F'[,=]' '/NNLS solver:/ {gsub(/ /, "", $2); print $2}' ${myPath}/noscale_eqp_online${n}rs${s}dt${dt}.txt)
n_value=$(awk -F'[,=]' '/NNLS solver:/ {gsub(/ /, "", $4); print $4}' ${myPath}/noscale_eqp_online${n}rs${s}dt${dt}.txt)
printf "EQP,$t,${dt},${s},${fractions[$n]},${n_x[$n]},${n_v[$n]},${nqp},${nvar},${m_value},${n_value},${TT},${err_x},${err_v}\n" >> "$output"
done
break
done done done
