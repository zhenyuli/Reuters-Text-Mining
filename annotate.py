#!/usr/bin/python
# -*- coding: latin-1 -*-
import sys
import nltk
from nltk.stem.snowball import SnowballStemmer
from nltk.collocations import *
import json
import  csv

def traverse(t,names,types):
	try: t.label()
	except AttributeError: return
	else:
		if t.height() == 2: # Leaf Node
			types.append(t.label())
			tokens=[token for token,tag in t]
			names.append('_'.join(tokens).lower())
		for child in t:
			traverse(child,names,types)

if len(sys.argv) < 2:
	print 'No file specified.'
	exit(0)
inFilePath=str(sys.argv[1])
outFilePath=inFilePath+'.annotated'
print 'Processing file: ',inFilePath
print 'Output file: ',outFilePath

bigram_measures = nltk.collocations.BigramAssocMeasures()
f1 = open(inFilePath,'r')
f2 = open(outFilePath,'w')
reader = csv.reader(f1,delimiter=',',quotechar='"')
writer = csv.writer(f2,delimiter=' ',quotechar='"',quoting=csv.QUOTE_ALL)

for line in reader:
	# Tokenize
	tokens = nltk.word_tokenize(line[0].encode('utf-8'))
	# Pos Tag
	tagged = nltk.pos_tag(tokens)
	tags = [tag for token,tag in tagged]

	# Stemming and Convert to lower case
	stemmer = SnowballStemmer("english",ignore_stopwords=True)
	stemmed_tokens = [stemmer.stem(word).lower() for word in tokens]

	# Find Bigrams and Trigrams
	finder = BigramCollocationFinder.from_words(stemmed_tokens)
	finder.apply_freq_filter(3)
	token_bigrams = sorted(finder.ngram_fd.items(), key=lambda t: (-t[1],t[0]))[:10]

	finder2 = BigramCollocationFinder.from_words(tags)
	finder2.apply_freq_filter(3)
	tag_bigrams = sorted(finder2.ngram_fd.items(), key=lambda t: (-t[1],t[0]))[:10]

	finder3 = TrigramCollocationFinder.from_words(stemmed_tokens)
	finder3.apply_freq_filter(3)
	token_trigrams = sorted(finder3.ngram_fd.items(), key=lambda t: (-t[1],t[0]))[:10]

	finder4 = TrigramCollocationFinder.from_words(tags)
	finder4.apply_freq_filter(3)
	tag_trigrams = sorted(finder4.ngram_fd.items(), key=lambda t: (-t[1],t[0]))[:10]


	# Named Entity Recognition
	# Note: lowered case and stemmed tokens are not recognised
	entities = nltk.chunk.ne_chunk(tagged)
	entity_names = []
	entity_types = []
	traverse(entities,entity_names,entity_types)

	# Construct A Dictionary for features
	doc_features = []
	doc_features.extend(stemmed_tokens)
	doc_features.extend(tags)
	doc_features.extend(entity_names)
	doc_features.extend(entity_types)

	#Add Ngrams
	ngrams=token_bigrams
	ngrams.extend(tag_bigrams)
	ngrams.extend(token_trigrams)
	ngrams.extend(tag_trigrams)
	for ngram in ngrams:
		s = '_'.join(ngram[0])
		for i in range(0,ngram[1]):
			doc_features.append(s)
	# Write to file
	writer.writerow([' '.join(doc_features)])
f1.close()
f2.close()
