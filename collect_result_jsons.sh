#!/bin/bash

resultdir=$1

if [ $1 == "" ]; then
  echo "You must specify a result directory"
  exit 1
fi

if [ ! -d $resultdir ]; then 
  echo "You must specify an existing result directory - Cannot find directory $resultdir"
  exit 1
fi


set -x

basedir=$(pwd)


# Currently the result processing happens in two steps.
# First the output files are processed - One for each concurrency for each
# experiment:

# process_result.py:

# Take the arguments:

# hw = sys.argv[1]
# tp_size = int(sys.argv[2])
# result_filename = sys.argv[3]
# framework = sys.argv[4]
# precision = sys.argv[5]

# load results, process and save:

# with open(f'{result_filename}.json') as f:
#     bmk_result = json.load(f)
#
# ...
#
# with open(f'agg_{result_filename}.json', 'w') as f:
#    json.dump(data, f, indent=2)


for task in 1k1k 1k8k 8k1k; do  

mkdir -p $resultdir/agg_$task 


cd $resultdir
filename=$(basename $(ls *$task*.json | head -n 1))

model=$(echo $filename | cut -d '_' -f 1 )
seqlens=$(echo $filename | cut -d '_' -f 2)
precision=$(echo $filename | cut -d '_' -f 3)
framework=$(echo $filename | cut -d '_' -f 4)
hw=$(basename $filename .json | rev | cut -d '_' -f 1 | rev)
tp_size=$(basename $filename .json | rev | cut -d '_' -f 3 | rev | sed -r 's/[^0-9]+//g')



for result_filename in *$task*.json ; do 
    python3 $basedir/utils/process_result.py $hw $tp_size $(basename $result_filename .json) $framework $precision
    mv agg_${result_filename} agg_${task}/
done

cd $basedir


# Second step is to collect the agg jsons into a single file:

# collect_results.py

# results_dir = Path(sys.argv[1])
# exp_name = sys.argv[2]

# agg_results = []
# for result_path in results_dir.rglob(f'*.json'):
#     with open(result_path) as f:
#         result = json.load(f)
#     agg_results.append(result)

# with open(f'agg_{exp_name}.json', 'w') as f:
#     json.dump(agg_results, f, indent=2)

mkdir -p $resultdir/json
cd $resultdir/json
python3 $basedir/utils/collect_results.py ../agg_${task}/ ${model}_${seqlens}

cd $basedir
done

echo "Results collected to"
find $resultdir/json/ -name "agg_${model}_*.json"
