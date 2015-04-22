library(mclust);
library(topicmodels);
library(fpc);
library(cluster);

# Function to find scatter of a group of points
# input D	matrix of data points (columns are dimensions)
scatter<-function(D){
	# Find Cluster Mean
	center<-apply(D,2,mean);
	# Subtract data point from center
	D<-sweep(D,MARGIN=2,center,FUN="-");
	# Find scatter matrix
	S<-t(D)%*%D;
	# Find scatter
	scat<-sum(diag(S));

	return(scat);
}

# function to measure scatter of a set of data points
# input	D			list of data points
# input	clusters	list of clusters that the data points belong to
measure_scatter<-function(D,clusters){
	# Tabulate all clusters
	freq_tab<-table(clusters);
	# Find cluster labels
	cluster_labs<-as.numeric(names(freq_tab));
	# Find center of all points
	center<-apply(D,2,mean);
	# Find Scatter of all clusters
	tot_S<-0; # Within Cluster Scatter
	tot_B<-0; # Between Cluster Scatter
	for (i in cluster_labs){
		Di<-D[clusters == i,];
		# Check if cluster contain less than 2 records
		if(!is.matrix(Di)){
			print(sprintf('Cluster %d has less than 2 records',i));
			next;
		}
		# Find cluster centre
		center_i<-apply(Di,2,mean);
		# Find within-cluster scatter
		Si<-scatter(Di);
		# Find between-cluster scatter
		Bi<-dim(Di)[1] * sum((center_i-center)^2);
		# Sum up scatters
		tot_S<-tot_S+Si;
		tot_B<-tot_B+Bi;
		print(sprintf('Cluster %d Between-Cluster Scatter: %f Within-Cluster Scatter:%f',
			i,Bi,Si));
	}
	print(sprintf('Before Cluster Scatter:%f',scatter(D)));
	print(sprintf('Total Between-Cluster Scatter:%f',tot_B));
	print(sprintf('Total Within-Cluster Scatter:%f',tot_S));
}

# function to find majority class label in each cluster
# input	class		list of class labels for all data points
# input	cluster		list of cluster assignments for all data points
majority_vote<-function(class,cluster){
	# Build frequency table
	cluster_tab<-table(cluster);
	# Loop over all cluster tags
	for(i in 1:length(cluster_tab)){
		# Find class labels belong to cluster i
		subclass<-class[cluster == i];
		# Build frequency table
		subclass_tab<-table(subclass);
		# Find majority class label of the cluster
		majority<-subclass_tab == max(subclass_tab);
		# Output Majority
		print(sprintf('Majority of Cluster %d [%d/%d] ---> Class %s [%d/%d]',
			i,cluster_tab[i],length(class),
			names(subclass_tab)[majority],subclass_tab[majority],sum(subclass_tab)));
	}
}

args <- commandArgs(trailingOnly=T);
if(length(args) < 1){
	print('Usage: ./clustering.R cluster_method options');
	print('Cluster Methods: pam,hclust[optional:single|average|complete],dbscan[optional:epsilon(0-1)],mclust');
}
stopifnot(length(args)>0);


#Prepare Data
load('./data/dtm.Rdata');
data<-dtm;
data<-scale(data);

doc_tags<-read.csv('./data/doc_tags.csv',header=T);
class<-doc_tags$tags;

cluster<-NULL;

if(args[1] == 'pam'){
	# K-Means Clustering
	print('Performing PAM Clustering')
	pam_fit<-pam(data,10);
	cluster<-pam_fit$cluster;
	save(pam_fit,file='./data/pam_fit.Rdata')
	
	# Build Silhouette
	pam_si<-silhouette(cluster,dist(data,'euclidean'));
	save(pam_si,file='./data/pam_si.Rdata');
}
if(args[1] == 'hclust'){
	# Hierarchical Clustering
	method<-'single';
	if(length(args) > 1) method <- args[2];

	print('./Performing Hierarchical Clustering');
	print(sprintf('hclust method: %s',method));

	distance<-dist(data,'euclidean');
	hclust_fit<-hclust(distance,method=method);
	cluster<-cutree(hclust_fit, k=10);
	save(hclust_fit,file=sprintf('./data/hclust_fit_%s.Rdata',method));

	#Build Silhouette
	hclust_si<-silhouette(cluster,distance);
	save(hclust_si,file='./data/hclust_si.Rdata');
}
if(args[1] == 'dbscan'){
	eps<-0.5;
	if(length(args) > 1) eps <- as.numeric(args[2]);
	# DBSCAN Clustering
	print('Performning DBSCAN Clustering')
	dbscan_fit<-dbscan(data,eps);
	cluster<-dbscan_fit$cluster;
	save(dbscan_fit,file='./data/dbscan_fit.Rdata')

	# Build Silhouette
	dbscan_si<-silhouette(cluster,dist(data,'euclidean'));
	save(dbscan_si,file='./data/dbscan_si.Rdata');
}
if(args[1] == 'mclust'){
	# EM Clustering
	print('Performing EM Clustering')
	mclust_fit<-Mclust(data,10);
	cluster<-mclust_fit$classification;
	save(mclust_fit,file='./data/mclust_fit.Rdata')

	# Build Silhouette
	mclust_si<-silhouette(cluster,dist(data,'euclidean'));
	save(mclust_si,file='./data/mclust_si.Rdata');
}
#Measure Scatter
measure_scatter(data,cluster);
# Find Majority Class of Each Cluster
majority_vote(class,cluster);
