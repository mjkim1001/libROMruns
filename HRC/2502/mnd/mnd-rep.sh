#!/bin/bash
#SBATCH -N 1
#SBATCH -t 10:00:00
#SBATCH -p pbatch
#SBATCH --open-mode truncate

source _get_vecs.sh
myPath=../../../libROMruns/HRC/2502/mnd
output="${myPath}/mnd_rep.txt"
printf "method,energy_frac,rwdim,rrdim,nldim,nsr,nqp,time,error\n"  > "$output"
# Declare energy fraction array
fractions=(0.9 0.99 0.999 0.9999 0.99999 0.999999 1)

mixed_nonlinear_diffusion -p 1 -offline > "${myPath}/mnd_rep_offline1.txt"
mixed_nonlinear_diffusion -p 1 -merge -ns 1 > "${myPath}/mnd_rep_merge.txt"
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

srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -ns 1 -eqp > "${myPath}/mnd_rep_eqp_online${n}.txt"
        err=$(cat ${myPath}/mnd_rep_eqp_online${n}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_rep_eqp_online${n}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_rep_eqp_online${n}.txt |  grep 'Number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*' | sed -n 2p)
        printf "EQPGlobal,${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${nqp},${TT},${err}\n" >> "$output"
 
for ((qq=1; qq<=20; qq++)); do
if (( qq >= 1 && qq <= 10 )); then
    q=$((5 * qq))
else
    q=$((10 * (qq - 5)))
fi
 srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1 -ns 1 -maxnnls $q -eqp > "${myPath}/mnd_rep_eqp_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_rep_eqp_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_rep_eqp_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_rep_eqp_online${n}q${q}.txt |  grep 'Number of nonzeros in NNLS solution: ' | egrep -wo '[0-9]*' | sed -n 2p)
        printf "EQP,${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},${nqp},${TT},${err}\n" >> "$output"
done
for ((qq=1; qq<=31; qq++)); do
if (( qq >= 1 && qq <= 10 )); then
    q=$((5 * qq))
else
    q=$((100 * (qq - 10)))
fi	
	srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1  -nsr $q -hrtype sopt > "${myPath}/mnd_rep_sopt_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_rep_sopt_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_rep_sopt_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_rep_sopt_online${n}q${q}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "SOPT,${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},$((nqp*4)),${TT},${err}\n" >> "$output"

srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1  -nsr $q -hrtype gnat> "${myPath}/mnd_rep_pod_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_rep_pod_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_rep_pod_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_rep_pod_online${n}q${q}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "gappy-POD,${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},$((nqp*4)),${TT},${err}\n" >> "$output"
srun -n 1 -p pdebug mixed_nonlinear_diffusion -online -rrdim ${n_r[$n]} -rwdim ${n_w[$n]} -nldim ${n_nl[$n]} -p 1  -nsr $q -hrtype qdeim > "${myPath}/mnd_rep_qdeim_online${n}q${q}.txt"
        err=$(cat ${myPath}/mnd_rep_qdeim_online${n}q${q}.txt | grep "Relative l2 error of ROM solution " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        TT=$(cat ${myPath}/mnd_rep_qdeim_online${n}q${q}.txt | grep "Elapsed time for time integration loop " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
        nqp=$(cat ${myPath}/mnd_rep_qdeim_online${n}q${q}.txt | grep 'sample mesh has ' | egrep -wo '[0-9]*' | head -1)
        printf "QDEIM,${fractions[$n]},${n_w[$n]},${n_r[$n]},${n_nl[$n]},${q},$((nqp*4)),${TT},${err}\n" >> "$output"
done
done
