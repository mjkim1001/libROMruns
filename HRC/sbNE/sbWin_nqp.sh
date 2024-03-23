myPath=./dependencies/libROM/libROMruns/HRC/sbNE
for t in 0.1; do
for rs in 2;do
output="${myPath}/sbWin${t}_nqp.txt"
printf "method,t,w,ws,sfac,mesh,TT3,TT4,ErrX,ErrV,ErrE\n"  > "$output"
for((ww=1 ;ww<=2;ww++)) do
ws=$((ww*20))
TT1=$(cat ${myPath}/sb_offline${t}w${ww}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
w=$(find ./run/sbWin -name 'basisE*' | wc -l)
for ((q=2; q<= 10; ++q)) do
errX=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_sopt_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT3=$(cat ${myPath}/sb_sopt_online${t}q${q}ws${ws}rs${rs}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
dt=$(cat ${myPath}/sb_sopt_online${t}q${q}ws${ws}rs${rs}.txt | grep "ROM online basis change for " | awk '{print $12}' | tr '\n' ',')
nqp=$(cat ${myPath}/sb_sopt_hyper${t}q${q}ws${ws}rs${rs}.txt | grep "sample mesh has " | awk '{print $4}' | tr '\n' ',' )
printf "sopt,${t},${ws},${q},${nqp}${TT3},${errX},${errV},${errE},${dt}\n" >> "$output"

errX=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_qdeim_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT3=$(cat ${myPath}/sb_qdeim_online${t}q${q}ws${ws}rs${rs}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_qdeim_hyper${t}q${q}ws${ws}rs${rs}.txt | grep "sample mesh has " | awk '{print $4}' | tr '\n' ',' )
dt=$(cat ${myPath}/sb_qdeim_online${t}q${q}ws${ws}rs${rs}.txt | grep "ROM online basis change for " | awk '{print $12}' | tr '\n' ',')
printf "qdeim,${t},${ws},${q},${nqp}${TT3},${errX},${errV},${errE},${dt}\n" >> "$output"

errX=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Position Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errE=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Energy Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
errV=$(cat ${myPath}/sb_gnat_restore${t}q${q}ws${ws}rs${rs}.txt | grep "Velocity Rel. DIFF norm " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
TT3=$(cat ${myPath}/sb_gnat_online${t}q${q}ws${ws}rs${rs}.txt | grep "Elapsed time for time loop: " | egrep -wo 'nan|[0-9]*\.([0-9]*|[0-9]*e\-[0-9]*|[0-9]*e\+[0-9]*)')
nqp=$(cat ${myPath}/sb_gnat_hyper${t}q${q}ws${ws}rs${rs}.txt | grep "sample mesh has " | awk '{print $4}'| tr '\n' ',' )
dt=$(cat ${myPath}/sb_gnat_online${t}q${q}ws${ws}rs${rs}.txt | grep "ROM online basis change for " | awk '{print $12}' | tr '\n' ',')
printf "gnat,${t},${ws},${q},${nqp}${TT3},${errX},${errV},${errE},${dt}\n" >> "$output"
done
done
done
done
