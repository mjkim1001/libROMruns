#!/bin/bash
#SBATCH -N 1
#SBATCH -t 10:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate
source _get_vecs.sh
myPath=../../../libROMruns/clsTh/mnd
output="${myPath}/mndTh.txt"
#printf "p,method,n,energy_frac,rwdim,rrdim,nldim,nsr,time,error\n"  > "$output"
# Declare energy fraction array
fractions=(0.9 0.99 0.999 0.9999 0.99999 0.999999 1)
mixed_nonlinear_diffusion -p 1 -offline -id 0 -sh 0.25 > "${myPath}/mnd_pred_offline1.txt"
mixed_nonlinear_diffusion -p 1 -offline -id 1 -sh 0.15 > "${myPath}/mnd_pred_offline2.txt"
mixed_nonlinear_diffusion -p 1 -offline -id 2 -sh 0.35 > "${myPath}/mnd_pred_offline3.txt"
mixed_nonlinear_diffusion -p 1 -merge -ns 3 > "${myPath}/mnd_pred_merge.txt"
mixed_nonlinear_diffusion -p 1 -offline -id 3 -sh 0.3 > "${myPath}/mnd_pred_off4.txt"

# Read the text file containing energy fractions and basis vectors
w_name="mergedSV_W"
IFS=" " read -r -a n_w <<<"$(get_vectors $w_name)"
r_name="mergedSV_R"
IFS=" " read -r -a n_r <<<"$(get_vectors $r_name)"
nl_name="mergedSV_FR"
IFS=" " read -r -a n_nl <<<"$(get_vectors $nl_name)"
echo "Recovering number of basis vectors:"
for ((n = 3; n < "${#fractions[@]}"; n++)); do
echo "frac: ${fractions[$n]}, w-basis vectors: ${n_w[$n]}, r-basis vectors: ${n_r[$n]}, nl-basis vectors: ${n_nl[$n]}"
for p in 0.5 0.6; do
for((qq=1 ;qq<=20;qq++)) do
q=$((2*qq+ n_nl[$n]))
        srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype sopt > "${myPath}/mnd_pred_sopt_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_sopt_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_sopt_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "${1},SOPT,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
	srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype sopt -precls -thRate $p > "${myPath}/mndcls_pred_sopt_online${n}q${q}.txt"
        err=$(cat ${myPath}/mndcls_pred_sopt_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mndcls_pred_sopt_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "${p},clsthSOPT,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
	srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype sopt -thRate $p > "${myPath}/mnd_pred_soptTh_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_soptTh_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_soptTh_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "${p},thSOPT,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
        
	srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype qdeim > "${myPath}/mnd_pred_qdeim_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_qdeim_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_qdeim_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "1,QDEIM,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
	srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype qdeim -precls -thRate $p > "${myPath}/mndcls_pred_qdeim_online${n}q${q}.txt"
        err=$(cat ${myPath}/mndcls_pred_qdeim_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mndcls_pred_qdeim_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "${p},clsthQDEIM,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
	srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype qdeim -thRate $p > "${myPath}/mnd_pred_qdeimTh_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_qdeimTh_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_qdeimTh_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "${p},thQDEIM,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"

done done done
