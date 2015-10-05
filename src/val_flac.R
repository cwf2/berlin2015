# Thematic work on Valerius Flaccus

# packages

library(data.table)
library(parallel)
library(tm)
library(topicmodels)
library(mclust)
library(XML)
library(MASS)

source(file.path("src","tesserae.R"))

# functions

load.file <- function(file) {
  # read a single text and produce a data.table

  cat("Reading", file, "... ")

  # parse the Tesserae XML file
  doc <- xmlParse(file)

  # get author and work from Tesserae text id
  tess.id <- xmlGetAttr(getNodeSet(doc, "/TessDocument")[[1]], "id")
  auth <- sub("\\..*", "", tess.id)
  work <- sub(".*\\.", "", tess.id)

  # print a tally when done
  count <- 0
  on.exit(cat(count, "lines\n"))

  # process lines, build a data.table
  rbindlist(
    xpathApply(doc, "//TextUnit", function(node) {
      count <<- count + 1

      data.table(
        auth = auth,
        work = work,
        loc = xmlGetAttr(node, "loc"),
        verse = xmlValue(node)
      )
    })
  )[,
    verse := iconv(verse, from = "ASCII", to = "UTF-8", mark = T)
    ][,
      unitid := .I
      ]
}

load.corpus <- function(index.file) {
  # load a set of Tesserae texts and construct a corpus

  cat("Loading corpus from", index.file, "\n")

  files <- scan(index.file, what="character", sep="\n")
  cat("Reading", length(files), "files\n")

  rbindlist(lapply(files, load.file))
}


cluster.series <- function(x, k = 5, nreps = 10, cores = NA) {
  # generate a series of k-means clusterings

  cat("Generating", nreps, "classifications with k =", k, "\n")

  inner.function <- function(i) {
    t0 <- Sys.time()
    on.exit(
      cat(
        paste(" - [", i, "/", nreps, "]", sep=""),
        "...",
        difftime(Sys.time(), t0, units = "min"),
        "minutes\n")
    )
    kmeans(x, k)$cluster
  }

  do.call(cbind, ifelse(is.na(cores),
    mclapply(1:nreps, inner.function, mc.cores = cores),
    lapply(1:nreps, inner.function)
  ))
}

#
# main
#

# 0. preliminaries

set.seed(19810111)
sample.size <- 30
stopwords.maxsamples <- 0.5
ntopics <- 50
ncores <- 3

# 1. preprocessing the texts

# load latin corpus
la.verse <- load.corpus("data/texts/la.index.txt")

# load latin stemmer
la.stemmer <- build.stemmer.table(
  stems.file = file.path("data", "tesserae", "la.lexicon.csv"),
  resolve = file.path("data", "tesserae", "la.word.freq")
)

# 2. sampling

# assign samples to verse lines
cat("Sampling\n")

samples <- la.verse[,
  .(auth, work, loc, verse, int.grp = ceiling(unitid / sample.size))
][,
  .(
    sampleid = .GRP,
    start = min(.I),
    end = max(.I),
    lstart = loc[which.min(.I)],
    lend = loc[which.max(.I)],
    text = paste(
      unlist(la.stemmer(standardize(unlist(strsplit(verse, " "))))),
      collapse = " "
    )
  ),
  by = .(auth, work, int.grp)
][
  nchar(text) > mean(nchar(text)) - 3 * sd(nchar(text))
  & nchar(text) < mean(nchar(text)) + 3 * sd(nchar(text)),
  .(auth = factor(auth), work = factor(work), start, end, sampleid, lstart, lend, text)
]


# 2. Generate feature vectors for samples
#    a) tf-idf weights using tm

cat("Building tf-idf weighted document term matrix\n")

# build samples into a tm-style corpus
tm.corp <- VCorpus(VectorSource(
  sapply(samples$text, paste, collapse = " ")
))

# calculate document-term matrix with tf-idf weights
dtm.tfidf <- DocumentTermMatrix(tm.corp, control=list(
  weighting = weightTfIdf,
  bounds = list(global = c(2, stopwords.maxsamples * nrow(samples)))
))

feat.tfidf <- as.matrix(dtm.tfidf)

cat("Calculating PCA for tf-idf scores")
pca.tfidf <- prcomp(feat.tfidf)

#  2. b) author-adjusted tf-idf weights

sig.base <- colMeans(feat.tfidf)

cat ("Trying to remove author signal\n")
feat.adjusted <- feat.tfidf
for (name in levels(samples$auth)) {
  cat(" -", name, "\n")
  sig.auth <- colMeans(feat.tfidf[samples$auth == name,]) - sig.base
  feat.adjusted[samples$auth == name,] <- t(t(feat.tfidf[samples$auth == name,]) - sig.auth)
}

cat("Calculating PCA for author-adjusted tf-idf scores")
proj.pca.adjusted <- predict(pca.tfidf, feat.adjusted)
pca.adjusted <- prcomp(feat.adjusted)

# 2. c) LDA

cat("Building tf document-term matrix for LDA\n")
dtm.tf <- DocumentTermMatrix(tm.corp, control=list(
  bounds = list(global = c(2, stopwords.maxsamples * nrow(samples)))
))

cat("Generating topic model with", ntopics, "topics\n")
print(system.time(
  lda <- LDA(dtm.tf, k = ntopics)
))

feat.topics <- slot(lda, "gamma")
pca.topics <- prcomp(feat.topics)


#
# 3. Check k-means correlation with authorhsip
#

#  a) tf-idf
print(system.time(
  auth_test.tfidf.cl <- cluster.series(feat.tfidf, k = nlevels(samples$auth), nreps = 10, cores = ncores)
))
auth_test.tfidf <- apply(auth_test.tfidf.cl, 2, adjustedRandIndex, y=samples$auth)

#  b) author-adjusted tf-idf
print(system.time(
  auth_test.adjusted.cl <- cluster.series(feat.adjusted, k = nlevels(samples$auth), nreps = 10, cores = ncores)
))
auth_test.adjusted <- apply(auth_test.adjusted.cl, 2, adjustedRandIndex, y=samples$auth)


#
# 4. Check k-means stability for varying k
#

k.max <- 15
nreps <- 10

#  a) tfidf

cat("Checking stability for tfidf with k = 2 to", k.max, "\n")

kmcl.tfidf.cl <- do.call(cbind, lapply(2:k.max, function(k) {
  cat("k =", k, ": Generating", nreps, "clusters\n")

  t0 <- Sys.time()
  on.exit(cat("k =", k, ":", difftime(Sys.time(), t0, units = "min"),  "minutes\n"))

  cluster.series(feat.tfidf, k, nreps, ncores)
})
)

kmcl.tfidf.k.orig <- rep(2:k.max, each=nreps)

randscores.tfidf.k.orig <- lapply(2:k.max, function(k) {
  combn(which(kmcl.tfidf.k.orig == k), 2, function(i) {
    adjustedRandIndex(kmcl.tfidf.cl[,i[1]], kmcl.tfidf.cl[, i[2]])
  })
})
names(randscores.tfidf.k.orig) <- 2:k.max

randscores.tfidf.k.orig.nobs <- rep(choose(n, 2), k.max - 1)

boxplot(randscores.tfidf.k.orig, main = "tfidf\noriginal k")
