library(e1071);
library(randomForest);
library(topicmodels);
#Normalize features of dataset
normalize<-function(data){
	cols<-ncol(data);
	for(i in 1:cols){
		if(is.numeric(data[,i]))data[,i]<-data[,i]/sum(data[,i]);
	}
	return(data);
}
#Randomize the rows of dataset
randomize<-function(data){
	length<-nrow(data);
	indices<-1:length;
	rindices<-sample(indices,length,replace=F);
	data<-data[rindices,];
	return(data);
}
#This function does cross-validation
#input data	datamatrix
#input method	randomForest,SVM,naiveBayes,etc
#input K	K-foldvalidation
#return		confusion matrices of each fold
cross_validation<-function(data,method,K=10){
	#Calculate matrix length and size
	length<-nrow(data);
	partitionSize<-floor(length/K);
	#Confusion Matrix
	confusionMatrices<-list();
	#List of models
	models<-list()
	#Normalize Data
	data<-normalize(data);
	#Shuffle Data
	randomData<-randomize(data);
	#Perform Cross-Validation
	for(k in 1:K){
		# Debug
		print(sprintf('K-Fold: %d',k));
		#Get Traning Set
		startIdx<-(k-1)*partitionSize+1;
		indices<-startIdx:(startIdx+partitionSize-1);
		trainset<-randomData[-indices,];
		testset<-randomData[indices,];
		#Train Data
		ifelse(method=='svm',
			model<-svm(class~.,data=trainset,kernel=svm.kernel,
				gamma=svm.gamma,cost=svm.cost),
			ifelse(method=='naiveBayes',
				model<-naiveBayes(class~.,data=trainset),
				model<-randomForest(class~.,data=trainset,mtry=rf.mtry)
		));
		prediction<-predict(model,testset);
		#Construct Confusion Matrix
		tab<-table(actual=testset[,1],predicted=prediction);
		confusionMatrices[[k]]<-tab;
		models[[k]]<-model;
	}
	return(list(confusionMatrices=confusionMatrices,models=models));
}
#This function produce per class performance matrix from confusion matrix
#input matrix confusionmatrix
measure_performance<-function(mat){
	#Get Size of Matrix
	size<-nrow(mat);
	#Initialize Result
	result<-matrix(,nrow=size,ncol=6);
	col_names<-c('TP','FN','FP','Recall','Precision','F-measure');
	row_names<-rownames(mat);
	colnames(result)<-col_names;
	rownames(result)<-row_names;
	#Iterate over all class
	for(c in 1:size){
	#Calculate Performance Metrics
		TP<-mat[c,c];
		FN<-sum(mat[c,-c]);
		FP<-sum(mat[-c,c]);
		recall<-TP/(TP+FN);
		precision<-TP/(TP+FP);
		fmeasure<-(2*precision*recall)/(precision+recall);
		#SaveToResult
		result[c,1]<-TP;result[c,2]<-FN;result[c,3]<-FP;
		result[c,4]<-recall;result[c,5]<-precision;
		result[c,6]<-fmeasure;
	}
	return(result);
}
#This function produce the overall performance matrix
#input matrix per class performance matrix
#return over all performance matrix
get_overall_performance<-function(mat){
	result<-matrix(0,nrow=2,ncol=3);
	col_names<-c('Recall','Precision','F-measure');
	row_names<-c('micro-avg','macro-avg');
	colnames(result)<-col_names;
	rownames(result)<-row_names;
	#Micro Averaging
	TP<-sum(mat[,1]);
	FN<-sum(mat[,2]);
	FP<-sum(mat[,3]);
	result[1,1]<-TP/(TP+FN);
	result[1,2]<-TP/(TP+FP);
	result[1,3]<-2*result[1,2]*result[1,1]/(result[1,1]+result[1,2]);
	#Macro Averaging
	result[2,1]<-mean(mat[,4],na.rm=T);
	result[2,2]<-mean(mat[,5],na.rm=T);
	result[2,3]<-mean(mat[,6],na.rm=T);
	return(result);
}
# Fetch Command Line Arguments
args <- commandArgs(trailingOnly=T)
ifelse(length(args) > 1, method<-args[1], method<-'naiveBayes')
print(sprintf("Method: %s",method))
if(method == 'svm'){
	if(length(args) == 4){
		svm.kernel = args[2]
		svm.gamma = as.numeric(args[3])
		svm.cost = as.numeric(args[4])
	}
	else{
		svm.kernel='radial'
		svm.gamma = 0.01
		svm.cost = 10000
	}
	print(sprintf("Settings: Kernel:%s Gamma:%f Cost:%f",
		svm.kernel,svm.gamma,svm.cost))
}
if(method == 'randomForest'){
	if(length(args) == 2){
		rf.mtry = as.numeric(args[2])
	}
	else{
		rf.mtry = 4
	}
	print(sprintf("Settings: mtry:%f",rf.mtry))
}

#Prepare Data
data<-read.csv('./data/doc_tags.csv',header=T);
load('./data/lda.Rdata');
load('./data/dtm.Rdata');

print('Preparing Data.')
# Add prefix to feature names
colnames(dtm)<-paste0('feature.',colnames(dtm))
# Convert topic models to strings
doc.topics<-sapply(topics(lda),as.character);

# Extract the purpose and tags column
data<-data[,colnames(data) %in% c('purpose','tags')];
# Combine Tags with features
data<-cbind(data,doc.topics,dtm);

# Preparing class column
colnames(data)[2]<-'class'; # Replace Class Name
data$class<-sapply(data$class,as.character); # Convert to characters
data$class<-factor(data$class); # Factorize class

# Convert to data frame
data<-as.data.frame(data);

#Separate Training and Testing Set
train_set<-subset(data,purpose == 'train'); # Get Training Set
test_set<-subset(data,purpose == 'test'); # Get Training Set
train_set<-train_set[,2:dim(data)[2]]; # Remove Purpose Column
test_set<-test_set[,2:dim(data)[2]]; # Remove Purpose Column
#Do cross validation on train set and test set
K<-10;
print(sprintf('Starting %d-fold cross validation',K));
result<-cross_validation(rbind(train_set,test_set),method,K=K);
confusionMatrices<-result$confusionMatrices;
models<-result$models;

#Start Evaluation
print('Evaluation on training set')
#Do Micro Averaging
overallConfusionMatrix<-confusionMatrices[[1]];
for(i in 2:length(confusionMatrices)){
	overallConfusionMatrix<-overallConfusionMatrix+confusionMatrices[[i]];
}
accuracy<-sum(diag(overallConfusionMatrix))/sum(overallConfusionMatrix);
performanceMatrix<-measure_performance(overallConfusionMatrix);
print("Result of Micro-Averaging");
print(performanceMatrix);
print(get_overall_performance(performanceMatrix));
print(sprintf("Accuracy:%f",accuracy));
#Do Macro Averaging
accuracies<-1:K*0;
overallPerformanceMatrix<-measure_performance(confusionMatrices[[1]]);
accuracies[1]<-sum(diag(confusionMatrices[[1]]))/sum(confusionMatrices[[1]]);
for(i in 2:length(confusionMatrices)){
	performanceMatrix<-measure_performance(confusionMatrices[[i]]);
	overallPerformanceMatrix<-overallPerformanceMatrix+performanceMatrix;
	accuracies[i]<-sum(diag(confusionMatrices[[i]]))/sum(confusionMatrices[[i]]);
}
overallPerformanceMatrix[,4:6]<-overallPerformanceMatrix[,4:6]/K;
print("Result of Macro-Averaing");
print(overallPerformanceMatrix);
print(get_overall_performance(overallPerformanceMatrix));
std_accuracy<-sqrt(var(accuracies));
mean_accuracy<-mean(accuracies);
print(sprintf("MeanAccuracy=%f",mean_accuracy));
print(sprintf("99%% ConfidenceInterval[%f,%f]",
	mean_accuracy-2.58*std_accuracy,
	mean_accuracy+2.58*std_accuracy));
print(sprintf("95%% ConfidenceInterval[%f,%f]",
	mean_accuracy-1.96*std_accuracy,
	mean_accuracy+1.96*std_accuracy));
print(sprintf("90%% ConfidenceInterval[%f,%f]",
	mean_accuracy-1.64*std_accuracy,
	mean_accuracy+1.64*std_accuracy));

#Evaluation on test set
print('Evaluation on test set')
#Find best model
accuracy_rank<-rank(-accuracies);
best_model<-models[accuracy_rank == min(accuracy_rank)][[1]];
#Classification on test set
prediction<-predict(best_model,test_set);
#Construct Confusion Matrix
confusionMatrix<-table(actual=test_set[,1],predicted=prediction);
accuracy<-sum(diag(confusionMatrix))/sum(confusionMatrix);
print(confusionMatrix)
print(sprintf('Test Set: Accuracy=%f',accuracy))
