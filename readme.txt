1. Dependencies
	The following libraries must be installed in order to run the scripts.

	1.1. nltk (R)
	1.2. tm (R)
	1.3. topicmodels (R)
	1.4. cluster (R)
	1.5. mclust (R)
	1.6. e1071 (R)

2. How to run?

	The order to run the scripts are added as prefix to the file.

	2.1. Preprocessing
		R CMD BATCH ./1_preprocessing.R
	2.2. Feature Engineering
		./2_annotate.sh
		R CMD BATCH ./3_feature_engineering.R
	2.3. Classification ( default Naive-Bayes)
		R CMD BATCH '--args naiveBayes' ./4_classification.R
		R CMD BATCH '--args svm 10 0.01' ./4_classification.R
		R CMD BATCH '--args randomForest 10' ./4_classification.R
	2.4. Clustering
		R CMD BATCH '--args pam' ./5_clustering.R
		R CMD BATCH '--args hclust' ./5_clustering.R
		R CMD BATCH '--args mclust' ./5_clustering.R
