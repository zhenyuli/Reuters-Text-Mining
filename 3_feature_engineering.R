library(SnowballC);
library(tm);
library(topicmodels);

# function to perform chi-square test on the specified class-term pair
# input	class			class label for chi2 test
# input term			term for chi2 test
# input tags			list of tags for documents
# input	doc_term_mat	document-term matrix
chi_test<-function(class,term,tags,doc_term_mat){
	# Summing Observed Data
	tab<-table(doc_term_mat[tags == class,term]>0);
	tab2<-table(doc_term_mat[tags != class,term]>0);

	# Construct Observed and Expected Matrix
	observed<-matrix(0,nrow=2,ncol=2);
	expected<-matrix(0,nrow=2,ncol=2);

	if('TRUE' %in% names(tab)) observed[1,1]<-tab[['TRUE']]; 
	if('FALSE' %in% names(tab)) observed[1,2]<-tab[['FALSE']];
	if('TRUE' %in% names(tab2)) observed[2,1]<-tab2[['TRUE']];
	if('FALSE' %in% names(tab2)) observed[2,2]<-tab2[['FALSE']];

	for(i in 1:2){
		for(j in 1:2){
			expected[i,j] <- sum(observed[i,])*sum(observed[,j])/sum(observed);
		}
	}

	diff<-observed-expected;
	chi_square<-sum(diff^2/expected);
	return(chi_square);
}

# function to select features using chi-square test
# input	tags			list of tags for documents
# input	doc_term_mat	document-term matrix
select_features<-function(tags,doc_term_mat){
	class_labels<-as.numeric(names(table(tags)));
	terms<-1:dim(doc_term_mat)[2];
	# Perform Chi Square for All Pairs of Class and Term
	chi2_tab<-matrix(0,nrow=length(class_labels),ncol=length(terms));
	for(i in 1:length(class_labels)){
		for(j in 1:length(terms)){
			chi2_tab[i,j] <- chi_test(class_labels[i],terms[j],
				tags,doc_term_mat);
		}
	}

	# Select The Best k Terms based on average chi2 value
	chi2_avg<-apply(chi2_tab,2,mean);
	ranks<-rank(-chi2_avg);
	selected_features<-which(ranks<=200);

	return(selected_features);
}

# Read data
doc_text<-read.csv('./data/doc_text.csv.annotated',header=T,stringsAsFactors=F);
doc_tags<-read.csv('./data/doc_tags.csv',header=T);


print('Start building document term matrix.')
# Define Stop Words
stopWords<- c(stopwords('english'),'reuter');

# Processing corpus
myCorpus <- Corpus(VectorSource(doc_text$doc.text));
myCorpus <- tm_map(myCorpus, removePunctuation);
myCorpus <- tm_map(myCorpus, removeNumbers);
myCorpus <- tm_map(myCorpus,removeWords,stopWords);
# Create Document-Term Matrix
dtm <- DocumentTermMatrix(myCorpus,control=list(bounds = list(global = c(10,Inf))));

# Select Features
print('Selecting Features')
dtm<-dtm[,select_features(as.matrix(doc_tags$tags),as.matrix(dtm))]

# Build LDA Model
print('Building LDA Model')
lda<-LDA(dtm,k=10);

# Store DTM and LDA model
dtm<-as.matrix(dtm);
save(dtm,file='./data/dtm.Rdata');
save(lda,file='./data/lda.Rdata')
