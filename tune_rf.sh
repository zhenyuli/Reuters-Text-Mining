#!/bin/sh
mtry=(1 2 4 6 8 10 12)

for m in "${mtry[@]}"; do
	command="R CMD BATCH --no-save --no-restore 
		'--args randomForest $m' 
		4_classification.R ./output/cv_rf_[$m]"
	echo $command
	R CMD BATCH --no-save --no-restore "--args randomForest $m" 4_classification.R ./output/cv_rf_[$m] &
done
