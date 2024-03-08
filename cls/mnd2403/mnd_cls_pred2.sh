#!/bin/bash
#SBATCH -N 1
#SBATCH -t 1:00:00
#SBATCH -p pdebug
#SBATCH --open-mode truncate
source _get_vecs.sh
myPath=../../../libROMruns/cls/mnd2403
output="${myPath}/mnd_pred_sopt_threhold.txt"
printf "method,energy_frac,rwdim,rrdim,nldim,nsr,time,error\n"  > "$output"
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
for ((n = 0; n < "${#fractions[@]}"; n++)); do
echo "frac: ${fractions[$n]}, w-basis vectors: ${n_w[$n]}, r-basis vectors: ${n_r[$n]}, nl-basis vectors: ${n_nl[$n]}"
for((qq=1 ;qq<=23;qq++)) do
q=$((qq+ 5*n_nl[$n]))
        mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype sopt > "${myPath}/mnd_pred_sopt_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_sopt_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_sopt_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "SOPT,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
	mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype sopt -precls > "${myPath}/mndcls_pred_sopt_online${n}q${q}.txt"
        err=$(cat ${myPath}/mndcls_pred_sopt_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mndcls_pred_sopt_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "clsSOPT,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
        mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype gnat > "${myPath}/mnd_pred_pod_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_pod_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_pod_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "gappy-POD,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
        mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -precls -hrtype gnat > "${myPath}/mndcls_pred_pod_online${n}q${q}.txt"
        err=$(cat ${myPath}/mndcls_pred_pod_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mndcls_pred_pod_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "clsgappy-POD,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
        
	mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype qdeim > "${myPath}/mnd_pred_qdeim_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_pred_qdeim_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_pred_qdeim_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "QDEIM,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"
	mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -sh 0.3 -id 3 -nsr $q -hrtype qdeim -precls > "${myPath}/mndcls_pred_qdeim_online${n}q${q}.txt"
        err=$(cat ${myPath}/mndcls_pred_qdeim_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mndcls_pred_qdeim_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        printf "clsQDEIM,${n},${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${TT},${err}\n" >> "$output"

done done
