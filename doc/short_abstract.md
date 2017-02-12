In this work in progress, we attempt to develop scene-level features for tone and context to improve the automatic scoring of word-level text-reuse for its allusive significance. Considering small samples of sequential verses in a bag-of-words model, we test several simple featuresets:
	* term frequencies with principal components analysis
	* tf-idf weights
	* tf-idf weights after an attempt to correct for authorship signal
	* term frequencies with Latent Dirichlet allocation
We then perform unsupervised clustering on the samples using k-means. The results of this clustering are compared with a human classification both of the automatically-generated samples and of scenes as delineated by critics. 
