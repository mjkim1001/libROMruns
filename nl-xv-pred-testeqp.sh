#!/bin/bash
#SBATCH -N 1
#SBATCH -t 1:00:00
#SBATCH -p pdebug
#SBATCH --open-mode truncate
source _get_vecs.sh
myPath=../../../eqpSerial
output="${myPath}/nlel_xv_pred_eqp.txt"

# Initialize the output file with headers 
printf "method,t, dt,ef,rxdim,rvdim,nqp,nvar,m,n,time,errx,errv\n"  > "$output"

# Declare an array for energy fractions
fractions=(0.9 0.99 0.999 0.9999 0.99999 0.999999 0.9999999)

# Loop over different time values
for t in 3.0; do #3.0 3.5 4.0 4.5; do
	dt=0.01

# Infinite loop to adjust dt based on convergence
while [ 1 ]; do
    # Remove existing basis files
    rm basis*
    no_convergence_flag=0

    # Offline Phase 1: Run the model and check for convergence
    nonlinear_elasticity_global_rom -offline -dt ${dt} -tf $t -s 14 -vs 100 -sc 0.9 -id 0 | tee "${myPath}/nlel_offline1t${t}dt${dt}.txt" |
    while IFS= read -r line
    do
        # If no convergence is detected, adjust dt and restart
        if [[ $line == *"PCG: No convergence!"* ]]; then
            echo "No convergence detected in offline phase 1. Decreasing dt."
            dt=$(echo "$dt - 0.002" | bc)
            no_convergence_flag=1
            break
        fi
    done

    # If no convergence in offline phase 1, restart the loop with the adjusted dt
    if [ $no_convergence_flag -eq 1 ]; then
        continue
    fi

    # Offline Phase 2
    nonlinear_elasticity_global_rom -offline -dt ${dt} -tf $t -s 14 -vs 100 -sc 1.1 -id 1 | tee "${myPath}/nlel_offline2t${t}dt${dt}.txt" |
    while IFS= read -r line
    do
        if [[ $line == *"PCG: No convergence!"* ]]; then
            echo "No convergence detected in offline phase 2. Decreasing dt."
            dt=$(echo "$dt - 0.002" | bc)
            no_convergence_flag=1
            break
        fi
    done

    if [ $no_convergence_flag -eq 1 ]; then
        continue
    fi

    # Merge Phase
    merge_output=$(nonlinear_elasticity_global_rom -merge -ns 2 -dt ${dt} -tf $t )
    echo "$merge_output" > "${myPath}/nlel_merge${t}dt${dt}.txt"

    # Check the merge output for errors. If error is detected, adjust dt and restart
    if [[ ! "$merge_output" =~ "Elapsed time for merging and building ROM basis:" ]]; then
        echo "Error detected in merge phase. Increasing dt."
        dt=$(echo "$dt + 0.002" | bc)
        continue
    fi

    # Offline Phase 3
    nonlinear_elasticity_global_rom -offline -dt ${dt} -tf $t -s 14 -vs 100 -sc 1.0 -id 2 | tee "${myPath}/nlel_offline3t${t}dt${dt}.txt" | 
		while IFS= read -r line
		do
		    if [[ $line == *"PCG: No convergence!"* ]]; then
		        echo "No convergence detected. Exiting loop."
						no_convergence_flag=1
		        break
		    fi
		done

		if [ $no_convergence_flag -eq 1 ]; then
            continue
    fi

# Read basis vectors and energy fractions from provided text files
x_name="mergedSV_X.txt"
IFS=" " read -r -a n_x <<<"$(get_vectors $x_name)"
v_name="mergedSV_V.txt"
IFS=" " read -r -a n_v <<<"$(get_vectors $v_name)"
nl_name="mergedSV_H.txt"
IFS=" " read -r -a n_nl <<<"$(get_vectors $nl_name)"

# Loop over fractions and gather results
#for ((n = 0; n < "${#fractions[@]}"; n++)); do
for ((n = 0; n < 2 ; n++)); do
	echo "frac: ${fractions[$n]}, x-basis vectors: ${n_x[$n]}, v-basis vectors: ${n_v[$n]}, nl-basis vectors: ${n_nl[$n]}"
    srun -n 1 -p pdebug nonlinear_elasticity_global_rom -online -rxdim ${n_x[$n]} -rvdim ${n_v[$n]} -dt ${dt} -tf $t -eqp -ns 2 -sc 1.0 -hdim 1  > "${myPath}/nlel_eqp_online${n}t${t}dt${dt}.txt"
        err_x=$(cat ${myPath}/nlel_eqp_online${n}t${t}dt${dt}.txt | grep "Relative error of ROM position (x) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        err_v=$(cat ${myPath}/nlel_eqp_online${n}t${t}dt${dt}.txt | grep "Relative error of ROM velocity (v) " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)' | tail -n1)
        TT=$(cat ${myPath}/nlel_eqp_online${n}t${t}dt${dt}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/nlel_eqp_online${n}t${t}dt${dt}.txt |  grep 'Global number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*')
	nvar=$(cat ${myPath}/nlel_eqp_online${n}t${t}dt${dt}.txt |  grep 'Number of velocity/deformation unknowns: ' | egrep -wo '[0-9]*')
	m_value=$(awk -F'[,=]' '/NNLS solver:/ {gsub(/ /, "", $2); print $2}' ${myPath}/nlel_eqp_online${n}t${t}dt${dt}.txt)
	n_value=$(awk -F'[,=]' '/NNLS solver:/ {gsub(/ /, "", $4); print $4}' ${myPath}/nlel_eqp_online${n}t${t}dt${dt}.txt)
	printf "EQP,$t,${dt},${fractions[$n]},${n_x[$n]},${n_v[$n]},${nqp},${nvar},${m_value},${n_value},${TT},${err_x},${err_v}\n" >> "$output"
done
break
done done
