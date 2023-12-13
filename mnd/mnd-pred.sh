#!/bin/bash
#SBATCH -N 1
#SBATCH -t 10:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate

source _get_vecs.sh
myPath=../../../libROMruns/mnd
output="${myPath}/mnd_pred_hr.txt"
printf "method,energy_frac,rwdim,rrdim,nldim,nsr,nqp,time,error\n"  > "$output"
# Declare energy fraction array
fractions=(0.9 0.99 0.999 0.9999 0.99999 0.999999 1)

mixed_nonlinear_diffusion -p 1 -offline -id 0 -sh 0.25 > "${myPath}/mnd_pred_offline1.txt"
mixed_nonlinear_diffusion -p 1 -offline -id 1 -sh 0.15 > "${myPath}/mnd_pred_offline2.txt"
mixed_nonlinear_diffusion -p 1 -offline -id 2 -sh 0.35 > "${myPath}/mnd_pred_offline3.txt"
mixed_nonlinear_diffusion -p 1 -merge -ns 3 > "${myPath}/mnd_pred_merge.txt"
mixed_nonlinear_diffusion -p 1 -offline -id 3 -sh 0.3 > "${myPath}/mnd_pred_off4.txt"
w_name="mergedSV_W"
IFS=" " read -r -a n_w <<<"$(get_vectors $w_name)"
r_name="mergedSV_R"
IFS=" " read -r -a n_r <<<"$(get_vectors $r_name)"
nl_name="mergedSV_FR"
IFS=" " read -r -a n_nl <<<"$(get_vectors $nl_name)"
echo "Recovering number of basis vectors:"
for ((m = 0; m < "${#fractions[@]}"; m++)); do
        echo "frac: ${fractions[$m]}, w-basis vectors: ${n_w[$m]}, r-basis vectors: ${n_r[$m]}, nl-basis vectors: ${n_nl[$m]}"

srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$m]} -rwdim ${n_w[$m]} -nldim ${n_nl[$m]} -p 1 -sh 0.3 -id 3 -ns 3 -eqp > "${myPath}/mnd_pred_eqp_online${m}.txt"
        err=$(cat ${myPath}/mnd_pred_eqp_online${m}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_eqp_online${m}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_pred_eqp_online${m}.txt |  grep 'Number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*' | sed -n 2p)
        printf "EQPGlobal,${fractions[$m]},${n_w[$m]},${n_r[$m]},${n_nl[$m]},${q},${nqp},${TT},${err}\n" >> "$output"
for ((qq=1; qq<=52; qq++)); do
 q=$((qq * 20))
srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$m]} -rwdim ${n_w[$m]} -nldim ${n_nl[$m]} -p 1 -sh 0.3 -id 3 -ns 3 -maxnnls $q -eqp > "${myPath}/mnd_pred_eqp_online${m}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_eqp_online${m}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_eqp_online${m}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_pred_eqp_online${m}q${q}.txt |  grep 'Number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*' | sed -n 2p)
        printf "EQP,${fractions[$m]},${n_w[$m]},${n_r[$m]},${n_nl[$m]},${q},${nqp},${TT},${err}\n" >> "$output"
#done
#	continue
	srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$m]} -rwdim ${n_w[$m]} -nldim ${n_nl[$m]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype sopt > "${myPath}/mnd_pred_sopt_online${m}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_sopt_online${m}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_sopt_online${m}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_pred_sopt_online${m}q${q}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "SOPT,${fractions[$m]},${n_w[$m]},${n_r[$m]},${n_nl[$m]},${q},$((nqp*4)),${TT},${err}\n" >> "$output"

srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$m]} -rwdim ${n_w[$m]} -nldim ${n_nl[$m]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype gnat > "${myPath}/mnd_pred_pod_online${m}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_pod_online${m}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_pod_online${m}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_pred_pod_online${m}q${q}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "gappy-POD,${fractions[$m]},${n_w[$m]},${n_r[$m]},${n_nl[$m]},${q},$((nqp*4)),${TT},${err}\n" >> "$output"
srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$m]} -rwdim ${n_w[$m]} -nldim ${n_nl[$m]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype qdeim > "${myPath}/mnd_pred_qdeim_online${m}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_qdeim_online${m}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_qdeim_online${m}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_pred_qdeim_online${m}q${q}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "QDEIM,${fractions[$m]},${n_w[$m]},${n_r[$m]},${n_nl[$m]},${q},$((nqp*4)),${TT},${err}\n" >> "$output"
done 
done
