#!/bin/sh
kernel=('linear')
gamma=(0.01 0.1 1 10 100)
cost=(0.01 0.001 0.1)

#gamma=(0.0001 0.0001 0.001 0.01 0.1 1 10 100 1000 10000)
#cost=(0.0001 0.0001 0.001 0.01 0.1 1 10 100 1000 10000)

for k in "${kernel[@]}"; do
	for c in "${cost[@]}"; do
		for g in "${gamma[@]}"; do
					command="R CMD BATCH --no-save --no-restore 
				'--args svm $k $g $c' 
				4_classification.R ./output/cv_svm_[$k]_[$g]_[$c] &"
			echo $command
			R CMD BATCH --no-save --no-restore "--args svm $k $g $c" 4_classification.R ./output/cv_svm_[$k]_[$g]_[$c] &
		done
	wait
	done
done
