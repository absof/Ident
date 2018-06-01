library(RNeo4j)
library(igraph)

graph <- startGraph(url = "https://dsi-bitcoin.doc.ic.ac.uk:7473/db/data/",
                   username = "guest_ro",
                   password = "imperialO_nly")


query <- "MATCH (b:Block)<-[:MINED_IN]-(t:Tx)<-[in:IN]-(txi:TxIn)<-[u:UNLOCK]-(a:Address)
WHERE b.height=364133
MATCH (oadr:Address)<-[l:LOCK]-(txo:TxOut)<-[out:OUT]-(t)
RETURN  a.address, ID(txi),ID(t),ID(txo), txo.value, oadr.address"

df <- cypher(graph, query)
checkdf<-df

addVertIfNotPresent <- function(g, ...){
  names2add <- setdiff(list(...),V(g)$name)
  v2add <- do.call(vertices,names2add)
  g <- g + v2add
}

iadr <- (checkdf[1][,1])
txi <- (checkdf[2][,1])
tx <- (checkdf[3][,1])
txo <- checkdf[4][,1]
vtxo <- checkdf[5][,1]
oadr <- checkdf[6][,1]
g<-graph(edges =,NULL,n=NULL,directed =FALSE)

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
pform_n_clusters <- function(df, n){
  cluster <- kmeans(df[, 1:4], n, nstart = 1)
  return(cluster)
}



