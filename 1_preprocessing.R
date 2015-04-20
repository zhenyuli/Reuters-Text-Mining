data<-read.csv('./data/reutersCSV.csv',header=T,stringsAsFactors=F);
print('Removing Missing Texts and Duplicated Entries')
# Remove Document pid, file name and Titles
cleaned<-data[,!(colnames(data) %in% c('pid','fileName','doc.title'))]
# Remove Empty Texts
cleaned<-cleaned[cleaned$doc.text != '',];
# Remove Duplicated Entries
cleaned<-unique(cleaned)
# Look for other incomplete cases
print('Incomplete Entries:')
print(table(complete.cases(cleaned)));
# Inspect attribute ranges
print('Inspecting Discrepencies:')
print(table(as.matrix(cleaned[,2:136]) %in% c(1,0)));
# Create tags
print('Combining Topics into Single Tags')
expanded<-data.frame(matrix(nrow=0,ncol=(dim(cleaned)[2]+1)));
colnames(expanded)<-colnames(cleaned)
colnames(expanded)[dim(expanded)[2]]<-'tags'
for(i in 2:136){
	tmp<-cleaned[cleaned[[i]] == 1,];
	if(dim(tmp)[1]>0) tmp$tags <- i;
	expanded<-rbind(expanded,tmp);
}
print('Select Top 10 most popular topics')
freq_tab<-table(expanded$tags);
topics<-as.numeric(names(freq_tab));
topic_ranks<-rank(-freq_tab);
pop_topics<-topics[which(topic_ranks<=10)];
expanded<-subset(expanded,tags %in% pop_topics);
print('Most popular topic:')
print(colnames(expanded)[pop_topics]);

print('Writing to files')
# Extract and Split columns
doc_tags<-expanded[,colnames(expanded) %in% c('purpose','tags')]; # purpuse,tags
doc_text<-expanded$doc.text;
# Write to file
write.csv(doc_tags,file='./data/doc_tags.csv',row.names=F);
write.csv(doc_text,file='./data/doc_text.csv',row.names=F);
