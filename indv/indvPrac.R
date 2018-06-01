library(RNeo4j)
library(igraph)
source("forceAtlas.R")

graph <- startGraph(url = "https://dsi-bitcoin.doc.ic.ac.uk:7473/db/data/",
                    username = "guest_ro",
                    password = "imperialO_nly")


query <- "MATCH (b:Block)<-[:MINED_IN]-(t:Tx)<-[in:IN]-(txi:TxIn)<-[u:UNLOCK]-(a:Address)
WHERE b.height=364133
MATCH (oadr:Address)<-[l:LOCK]-(txo:TxOut)<-[out:OUT]-(t)
RETURN  a.address, txi.ID(txi), ID(t),ID(txo), txo.value, oadr.address"

df <- cypher(graph, query)
checkdf<-df
names(checkdf) <- NULL
addVertIfNotPresent <- function(g, ...){
  names2add <- setdiff(list(...),V(g)$name)
  v2add <- do.call(vertices,names2add)
  g <- g + v2add
}
txi_t <- checkdf[,c(1,2,5,3)]
colnames(txi_t)<-(c("address", "ID", "value", "trans"))
u_txi_t <- subset.data.frame(txi_t, !duplicated(ID))
txi <- checkdf[,c(1,2,5)]
colnames(txi)<-(c("address", "ID", "value"))
u_txi <- subset.data.frame(txi, !duplicated(ID))
tx <- cbind(rep(NA, length(checkdf[,1])),checkdf[,c(3,5)])
colnames(tx)<-(c("address", "ID", "value"))
u_tx <- subset.data.frame(tx, !duplicated(ID))
txo <- checkdf[,c(6,4,5)]
colnames(txo)<-(c("address", "ID", "value"))
u_txo <- subset.data.frame(txo, !duplicated(ID))


all_vert <- rbind(u_txi, u_tx, u_txo)

in_out_vert <- rbind(u_txi, u_txo)

## A simple example with a couple of actors
## The typical case is that these tables are read in from files....

or <- c(rep("orange", length(u_txi$ID)))
r_1 <- c(rep(255, length(u_txi$ID)))
g_1 <- c(rep(165, length(u_txi$ID)))
b_1 <- c(rep(255, length(u_txi$ID)))

blck <- c(rep("black", length(u_tx$ID)))
r_2 <- c(rep(0, length(u_tx$ID)))
g_2 <- c(rep(0, length(u_tx$ID)))
b_2 <- c(rep(0, length(u_tx$ID)))

ble <- c(rep("blue", length(u_txo$ID)))
r_3 <- c(rep(0, length(u_txo$ID)))
g_3 <- c(rep(0, length(u_txo$ID)))
b_3 <- c(rep(255, length(u_txo$ID)))

r_v <- c(r_1,r_2,r_3)
g_v <- c(g_1,g_2,g_3)
b_v <- c(b_1,b_2,b_3)

col = c(or, blck, ble)
inputs <- data.frame(name=c(all_vert$ID),
                     address=c(all_vert$address),
                     color=col, r = r_v, g = g_v, b=b_v)

in_relations <- data.frame(from=u_txi$ID,
                        to=u_txi_t$trans, color = "orange", r = 255, g =165, b =0)
out_relations <- data.frame(from=tx$ID,
                            to=txo$ID, color = "blue", r = 0, g = 0, b = 255)
relations <- rbind(in_relations, out_relations)
u_address <- subset.data.frame(all_vert, duplicated(address))$address



for(i in 1:length(u_address)) {
  same_adr <- which(all_vert$address == u_address[i])
  if(length(same_adr) > 1) {
    for(j in 1:(length(same_adr)-1)) {
      adr_rel <- data.frame(from = paste(all_vert$ID[same_adr[j]]),
                            to = paste(all_vert$ID[same_adr[j+1]]),
                            color = "grey", r = 128, g=128, b = 128)
      relations <- rbind(relations, adr_rel)
    }
  }
}
adr_relations <- data.frame(from)
g <- graph_from_data_frame(relations, directed=TRUE, vertices=inputs)
for(i in 1:length(u_address)) {
  same_adr <- which(V(g)$address == u_address[i])
  if(length(same_adr) > 1) {
    for(j in 1:(length(same_adr)-1)) {
      g <- add.edges(g,c(paste(V(g)$name[same_adr[j]]),paste(V(g)$name[same_adr[j+1]])),attr = c(color="grey", r = 128, g = 128, b = 128))
    }
  }
}
lay <- layout.drl(g)
V(g)$x <-lay[,1]
V(g)$y <-lay[,2]
write_graph(g, "vis", "graphml")
tx  <- readLines("~/indv/vis")
tx  <- gsub(pattern = "v_", replace = "", x = tx)
tx  <- gsub(pattern = "name", replace = "label", x = tx)
tx2  <- gsub(pattern = "e_", replace = "", x = tx)
writeLines(tx2, con="~/indv/vis")

plot(g, edge.arrow.size =0, vertex.size =2, vertex.label = NA)



utxi <- unique(txi)
utx <- unique(tx)
utxo <- unique(txo)
for(i in 1:length(utxi)) {
  g <- g + vertex(utxi[i], color = "orange",address = iadr[which(txi == utxi[i])][1], value = 0)
}
for(i in 1:length(utx)) {
  g <- g + vertex(utx[i], color = "black", value = 0)
}
for(i in 1:length(utxo)) {
  g <- g + vertices(utxo[i],  color = "blue",address = oadr[which(txo == utxo[i])][1], value = vtxo[which(txo == utxo[i])])
}


for(i in 1: length(checkdf[1][,1])) {
  inp <- paste(checkdf[2][,1][i])
  tran <- paste(checkdf[3][,1][i])
  outp <- paste(checkdf[4][,1][i])
  g <- add.edges(g,c(inp, tran),color="orange")
  g <- add.edges(g,c(tran, outp) ,color="blue")
}
u_address <- unique(V(g)$address)
for(i in 1:length(u_address)) {
  same_adr <- which(V(g)$address == u_address[i])
  if(length(same_adr) > 1) {
    for(j in 1:(length(same_adr)-1)) {
      g <- add.edges(g,c(paste(V(g)$name[same_adr[j]]),paste(V(g)$name[same_adr[j+1]])),color="grey")
    }
  }
}




get_graph_info <- function(graph){
  m_deg  <- mean(degree(g))
  tot_val <- sum(V(g)$value)
  n_in <- length(which(V(g)$color == "orange"))
  n_out <- length(which(V(g)$color == "blue"))
  i_o_ratio <- n_in/n_out
  graph_info = list(mean_degree = m_deg, total_value = tot_val,
                    n_inputs = n_in, n_outputs = n_out,
                    in_out_ratio = i_o_ratio)
  return(graph_info)
}

form_data_frame <- function(graph_list){
  df <- data.frame(get_graph_info(graph_list[1]))
  for(in in 2:length(graph_list)) {
    df <- rbind(df, graph_list[i])
  }
  return(df)
}
fileConn<-file("ml")
txt <- c("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", 
         "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\"",

"<key attr.name=\"label\" attr.type=\"string\" for=\"node\" id=\"label\"/>",
  
  "<key attr.name=\"Edge Label\" attr.type=\"string\" for=\"edge\" id=\"edgelabel\"/>",
  
  "<key attr.name=\"weight\" attr.type=\"double\" for=\"edge\" id=\"weight\"/>",
  
  "<key attr.name=\"Edge Id\" attr.type=\"string\" for=\"edge\" id=\"edgeid\"/>",
  
  "<key attr.name=\"r\" attr.type=\"int\" for=\"node\" id=\"r\"/>",
  
  "<key attr.name=\"g\" attr.type=\"int\" for=\"node\" id=\"g\"/>",
  
  "<key attr.name=\"b\" attr.type=\"int\" for=\"node\" id=\"b\"/>",
  
  "<key attr.name=\"x\" attr.type=\"float\" for=\"node\" id=\"x\"/>",
  
  "<key attr.name=\"y\" attr.type=\"float\" for=\"node\" id=\"y\"/>",
  
  "<key attr.name=\"size\" attr.type=\"float\" for=\"node\" id=\"size\"/>",
  
  "<graph edgedefault=\"directed\">")
writeLines(txt, fileConn)
close(fileConn)
write(x, file = "ml",
      ncolumns = if(is.character(x)) 1 else 5,
      append = TRUE, sep = " ")
igraph_to_graphml <- function(graph){
  write(x, file = "data",
        ncolumns = if(is.character(x)) 1 else 5,
        append = FALSE, sep = " ")
}
pform_n_clusters <- function(df, n){
  cluster <- kmeans(df[, 1:4], n, nstart = 1)
  return(cluster)
}



