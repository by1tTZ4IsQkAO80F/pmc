#!/usr/bin/bash
# Run experiment. 
# Note this will submit many jobs to an LSF cluster manager. 
# To run locally, see python evaluate_model.py.
rdir="../results/"
ntrials=100
seeds=$(cat seeds.txt | head -n $ntrials)

mkdir -p $rdir

alphas=(
0.01
0.05
0.1
)
gammas=(
0.05
0.10
)
n_binses=(
5
10
)
rhos=(
0.01
0.05
0.1
)
methods=(
    "lr"
    "lr_mc"
    "lr_pmc"
    "rf"
    "rf_mc"
    "rf_pmc"
)
# Job parameters
# cores
N=1
q="epistasis_long"

mem=4096
timeout=3600
count=0

for s in ${seeds[@]} ; do
    for alpha in ${alphas[@]} ; do
        for gamma in ${gammas[@]} ; do
            for n_bins in ${n_binses[@]} ; do
                for rho in ${rhos[@]} ; do
                    for m in ${methods[@]} ; do
                        # ((i=i%N)); ((i++==0)) && wait
                        job_name="${m}_seed${s}_alpha${alpha}_gamma${gamma}_n_bins${n_bins}_rho${rho}" 
                        job_file="${rdir}/${job_name}" 

                        bsub -o "${job_file}.out" \
                             -n $N \
                             -J $job_name \
                             -q $q \
                             -R "span[hosts=1] rusage[mem=${mem}]" \
                             -W $timeout \
                             -M $mem \
                             python evaluate_model.py \
                                 -file data/mimic4_admissions.csv \
                                 -ml $m \
                                 -seed $s \
                                 -alpha $alpha \
                                 -gamma $gamma \
                                 -n_bins $n_bins \
                                 -rho $rho \
                                 -results_path $rdir 
                                 # >> $job_submission_file
                        ((++count))
                    done
                done
            done
        done
    done
done

echo "submitted $count jobs."
