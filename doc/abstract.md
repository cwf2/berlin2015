Thematic features for intertextual analysis
===========================================

Christopher W Forstall and Lavinia Galli Milić,  
Université de Genève  
cforstall@gmail.com

Abstract
--------

The study of intertextuality in Classical poetry often presents itself as a  specialized case of text-reuse detection: commentaries and other close readings of a work concern themselves with the identification and exegesis of phrases borrowed from earlier texts. Yet it has long been understood that larger-scale, structural parallelisms can also exist between texts (Genette 1997), and that these can provide the context necessary to establish an allusive or intertextual link between two phrases (Wills 1996). Automatic detection of intertextuality must take into account features at various scales: from individual phonemes to larger syntactic units and type scenes. This idea was proposed by, among others, Bamman and Crane (2008), and already forms one component of existing text-reuse search tools (for example, Büchler 2010).

In this work in progress, we attempt to develop scene-level features to improve the automatic scoring of word-level text-reuse for its allusive significance. Considering small samples of 30 sequential verses in a bag-of-words model, we test three different featuresets:
	* tf-idf weights
	* tf-idf weights after an attempt to correct for authorship signal
	* Latent Dirichlet allocation with 50 topics
We then perform unsupervised clustering on the samples using k-means. The results of this clustering are compared with a human classification both of the automatically-generated samples and of scenes as delineated by critics. 

In our first case study, we look at allusions in Statius' *Achilleid* to earlier works in both epic and elegiac genres. We situate each instance of text reuse within a larger tonal context, using the scenes identified by a recent commentary (Ripoll and Soubiran 2008) as well as a classifier trained to distinguish between epic and elegiac texts using a constellation of word frequencies.

In a second example, we look at the relationship between Valerius Flaccus' *Argonautica* and two important antecedents, the *Aeneid*, and the *Argonautica* of Apollonius. We ask whether a distinct thematic parallelism in the scene divisions at the midpoint of each text can be quantified and leveraged to adjust the rankings of text reuse detected within otherwise similar contexts. We then compare unsupervised clustering of scenes with the results of traditional philological exegesis, and conclude that for the present we cannot achieve the precision necessary to accurately gauge allusive significance through unsupervised methods alone. 

References
----------

D. Bamman and G. Crane (2008) The logic and discovery of textual allusion. Paper presented at the Second Workshop on Language Technology for Cultural Heritage Data (LaTeCH 2008), Marrakesh, Morocco.

M. Büchler, A. Geßner, T. Eckart, and G. Heyer (2010) Unsupervised detection and visualisation of textual reuse on ancient greek texts. *Journal of the Chicago Colloquium on Digital Humanities and Computer Science* 1(2).

G. Genette (2007) *Palimpsests: Literature in the Second Degree*. University of Nebraska Press, Lincoln.

J. Wills (1996) *Repetition in Latin Poetry: Figures of Allusion*. Clarendon Press.
