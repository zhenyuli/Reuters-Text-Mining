#!/bin/sh
# Split Document Texts
echo 'Removing Non-Printable Characters'
tr -cd '\11\12\15\40-\176' < ./data/doc_text.csv > ./doc_text.csv.tmp
mv ./doc_text.csv.tmp ./data/doc_text.csv
echo 'Spliting Document'
if [ -d './data/splits' ]; then
	rm ./data/splits/*
else
	mkdir ./data/splits
fi
split -l 1500 ./data/doc_text.csv
mv x* ./data/splits/
sed '1d' ./data/splits/xaa > tmpfile; 
mv tmpfile ./data/splits/xaa;
#Annotate Documents in parallel
echo 'Start Annotation'
for file in $(ls ./data/splits/x*);do
	echo 'Annotating '$file
	./annotate.py $file &
done
wait
echo 'Combining Files.'
rm ./data/dtm.*
rm ./data/doc_text.csv.annotated
echo '"doc.text"' > ./data/doc_text.csv.annotated
for file in $(ls ./data/splits/*annotated);do
	echo $file
	cat $file >> ./data/doc_text.csv.annotated
done
