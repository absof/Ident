library(RNeo4j)
library(igraph)
library(dplyr)
source("forceAtlas.R")


get_neo_query <- function(first_block, last_block){
  graph <- startGraph(url = "https://dsi-bitcoin.doc.ic.ac.uk:7473/db/data/",
                      username = "guest_ro",
                      password = "imperialO_nly")
  
  
  query <- paste("MATCH (b:Block)<-[:MINED_IN]-(t:Tx)<-[in:IN]-(txi:TxIn)<-[u:UNLOCK]-(a:Address)
                 WHERE b.height >=", first_block," AND b.height <= ", last_block,"
                 MATCH (txi)<-[:SPENT]-(txop:TxOut)
                 MATCH (oadr:Address)<-[l:LOCK]-(txo:TxOut)<-[out:OUT]-(t) 
                 RETURN a.address,txop.value, ID(txop), ID(txi), ID(t), ID(txo), txo.value, oadr.address", sep = "")
  
  dataf <- cypher(graph, query)
  return(dataf)

}
nice_plot <-function(graph) {
  plot(graph,  edge.width = 0.5,edge.arrow.size = 0,vertex.label = NA, vertex.size = log(V(graph)$amount+1))
}
generate_graph <- function(block_number){
  dataf <- get_neo_query(block_number, block_number)
  
  colnames(dataf) <- c("in_adr", "in_value", "in_out_ID","inID", "TID", "out_ID", "out_value", "out_adr")
  
  in_data <- dataf[,2:5]
  colnames(in_data)[2] <- "out" 
  out_data <- dataf[,5:7]
  colnames(out_data)[2] <- "out"
  
  #getting the transaction inputs without references of previous outpoints in the block
  u_orange <- unique(anti_join(in_data, out_data, by = "out"))
  
  inputs <- data.frame(name = paste(u_orange$inID), color = "orange", r = 255, g = 165, b = 0, amount = c(u_orange$in_value))
  in_to_trans <- data.frame(from=inputs$name,
                            to=paste(u_orange$TID), color = "orange", r = 255, g = 165, b = 0)
  
  #getting transaction inputs which spend outputs within the block and the relation with the inputs next transaction
  u_blue_in <- unique(inner_join(in_data, out_data, by = "out"))
  in_outs <- data.frame(name = paste(u_blue_in$out), color = "blue", r = 0, g = 0, b = 255, amount = c(u_blue_in$in_value))
  out_to_in <- data.frame(from = paste(u_blue_in$out), to = paste(u_blue_in$TID.x), color = "orange", r = 255, g = 165, b = 0)
  trans_to_out <- data.frame(from = paste(u_blue_in$TID.y), to = paste(u_blue_in$out), color = "blue", r = 0, g = 0, b = 255)
  
  #getting transaction outputs at the ends of the chain
  u_blue <- unique(anti_join(out_data, in_data, by = "out"))
  outputs <- data.frame(name = paste(u_blue$out), color = "blue", r = 0, g = 0, b = 255, amount = c(u_blue$out_value))
  trans_to_end <- data.frame(from = paste(u_blue$TID), to = paste(u_blue$out), color= "blue", r = 0, g = 0, b = 255)
  
  u_trans = unique(dataf$TID)
  trans_split <- split(dataf, with(dataf, interaction(TID)), drop = TRUE)
  u_in_trans <- lapply(trans_split, function(y){unique(y[,c(2,4)])})
  trans_val_split <- lapply(u_in_trans, function(y){sum(y$in_value)})
  trans_val <- adr_rel_frame <-data.frame(do.call(rbind, trans_val_split))
  trans_val$ID <- rownames(trans_val)
  trans <- data.frame(name = paste(c(trans_val[,2])) ,color = "white", r = 255, g = 255, b = 255, amount = trans_val[,1])
  
  
  verts <- rbind(inputs,outputs,in_outs, trans)
  
  in_d <- dataf[,c(1,2,3,4)]
  out_d <- dataf[,c(8,7,6)]
  colnames(in_d) <- c("adr", "value", "outID", "inID") 
  colnames(out_d) <- c("adr", "value", "outID") 
  
  in_adr <-unique(anti_join(in_d, out_d, by = "outID"))[,c(4,1)]
  colnames(in_adr) <- c("ID", "adr")
  out_in_adr <-unique(inner_join(in_d, out_d, by = "outID"))[,c(3,5)]
  colnames(out_in_adr) <- c("ID", "adr")
  out_adr <- unique(inner_join(out_d, in_d, by = "outID"))[,c(3,1)]
  colnames(out_adr) <- c("ID", "adr")
  
  vert_adr <- rbind(in_adr,out_in_adr, out_adr)
  
  adr_split <- split(vert_adr, with(vert_adr, interaction(adr)), drop = TRUE)
  
  u_adr_split <- lapply(adr_split, unique)
  
  
  id_adr <-lapply(u_adr_split, function(x){x$ID})
  
  id_groups <- id_adr[lapply(id_adr, length) > 1]
  
  rel_dummy <- NULL
  adr_rel <- lapply(id_groups, function(x){t(rbind(x[-1],x[-length(x)]))})
  adr_rel_frame <-data.frame(do.call(rbind, adr_rel))
  adr_rel_frame$color <- "grey"
  adr_rel_frame$r <- 192
  adr_rel_frame$g <- 192
  adr_rel_frame$b <- 192
  colnames(adr_rel_frame) <- c("from", "to", "color", "r", "g", "b")
  
  relations <- rbind(in_to_trans, out_to_in, trans_to_out, trans_to_end, adr_rel_frame)
  
  g <- graph_from_data_frame(relations, directed = TRUE, verts)
  layout_rel <- relations[,1:2]
  layout_ver <- verts[,1]
  
  layout_graph <- graph_from_data_frame(layout_rel, directed = TRUE, layout_ver)
  temp_layout <- layout_nicely(g)
  V(g)$x <- temp_layout[,1]
  V(g)$y <- temp_layout[,2]
  #V(g)$size=V(g)$amount
  plot(g, edge.width = 0.5,edge.arrow.size = 0, vertex.label = NA, vertex.size = 2)
  dir.create(file.path("~/indv/gephi/gephi-toolkit-demos/src/main/resources/org/gephi/toolkit/demos",block_number), showWarnings = TRUE)
  f_path <- paste("~/indv/gephi/gephi-toolkit-demos/src/main/resources/org/gephi/toolkit/demos/",block_number,"/block.graphml", sep = "")
  write_graph(g, f_path, "graphml")
  tx  <- readLines(f_path)
  tx2  <- gsub(pattern = "v_", replace = "", x = tx)
  tx2  <- gsub(pattern = "e_", replace = "", x = tx2)
  writeLines(tx2, con= f_path)
  return(g)

}
get_graph_info <- function(graph){
  l_path <- diameter(graph)
  m_deg  <- mean(degree(graph))
  tot_val <- sum(V(graph)$amount)
  n_in <- length(which(V(graph)$color == "orange"))
  n_out <- length(which(V(graph)$color == "blue"))
  i_o_ratio <- n_in/n_out
  graph_info = list(longest_path = l_path,mean_degree = m_deg, total_value = tot_val,
                    n_inputs = n_in, n_outputs = n_out,
                    in_out_ratio = i_o_ratio)
  return(graph_info)
}
pform_n_clusters <- function(df, n){
  cluster <- kmeans(df[, 1:5], n, nstart = 1)
  return(cluster)
}
create_cluster_graphs<- function(g, n_clusters, block_number) {
  
  dg <- decompose(g)
  
  g_info <- data.frame()
  for(i in 1:length(dg)) {
    g_info <- rbind(g_info,as.data.frame(get_graph_info(dg[[i]])))
  }

  clusters100 <- pform_n_clusters(g_info, n_clusters)
  comb_graphs <- vector("list", n_clusters) 
  for(j in 1:n_clusters) {
    sub_g <- rownames(g_info[clusters100$cluster==j,])
    sub_g_vert <- data.frame(name=integer(), color=character(), r=numeric(), g=numeric(), b=numeric(),amount=double())
    sub_vert <- data.frame(name=integer(), color=character(), r=numeric(), g=numeric(), b=numeric(),amount=double())
    sub_edge <- data.frame(from=integer(),to=integer(), color=character(), r=numeric(), g=numeric(), b=numeric())
    sub_edge_n <- data.frame(from=integer(),to=integer())
    names(sub_edge_n) <- c("from", "to")

    for(i in 1:length(sub_g)) {
      sub_ig <- dg[as.numeric(sub_g[i])][[1]]
      sub_g_vert <- (cbind(name=V(sub_ig)$name,color=as.character(V(sub_ig)$color),r=V(sub_ig)$r,g=V(sub_ig)$g
                       ,b=V(sub_ig)$b,amount=V(sub_ig)$amount))
      sub_vert <-rbind(sub_vert,sub_g_vert)
      sub_edge_n <- as.data.frame(get.edgelist(sub_ig))
      sub_edge<- rbind(sub_edge, as.data.frame(cbind(sub_edge_n,color=E(sub_ig)$color,r=E(sub_ig)$r,g=E(sub_ig)$g,b=E(sub_ig)$b)))
  
      #write_graph(dg[as.numeric(sub_g[i])][[1]], paste("~/indv/gephi/gephi-toolkit-demos/src/main/resources/org/gephi/toolkit/demos/cluster2island",i,".graphml",sep=""), "graphml")
      #tx  <- readLines(paste("~/indv/gephi/gephi-toolkit-demos/src/main/resources/org/gephi/toolkit/demos/cluster2island",i,".graphml",sep=""))
      #tx2  <- gsub(pattern = "v_", replace = "", x = tx)
      #tx2  <- gsub(pattern = "e_", replace = "", x = tx2)
      #writeLines(tx2, con=paste("~/indv/gephi/gephi-toolkit-demos/src/main/resources/org/gephi/toolkit/demos/cluster2island",i,".graphml",sep=""))
      #sub_g <- dg[as.numeric(sub_g[i])][[1]]
      #e_list <- as.data.frame(get.edgelist(sub_g))
      #v_list <- as.data.frame(list(Vertex=V(sub_g)), stringsAsFactors=FALSE)
      #verts <- verts + dg[[as.numeric(sub_g[i])]]
      #pdf(plot(dg[as.numeric(sub_g[i])], edge.width = 0.5,edge.arrow.size = 0,vertex.label = NA, vertex.size = V(dg[[as.numeric(sub_g[i])]])$amount))
    }
    names(sub_edge) <- c("from","to","color","r","g","b")
    names(sub_vert) <- c("name","color","r","g","b","amount")
    sub_vert$r <- as.numeric(sub_vert$r)
    sub_vert$g <- as.numeric(sub_vert$g)
    sub_vert$b <- as.numeric(sub_vert$b)
    sub_vert$amount <- as.numeric(sub_vert$amount)
    comb_graphs[[j]] <-graph_from_data_frame(sub_edge, directed = TRUE, sub_vert)
    
    dir <- paste("~/indv/gephi/gephi-toolkit-demos/src/main/resources/org/gephi/toolkit/demos/",block_number,"/cluster",j ,".graphml",sep="")
    write_graph(comb_graphs[j][[1]], dir, "graphml")
    tx  <- readLines(dir)
    tx2  <- gsub(pattern = "v_", replace = "", x = tx)
    tx2  <- gsub(pattern = "e_", replace = "", x = tx2)
    writeLines(tx2, con=dir)
  }
  return(comb_graphs)
}

build_train_data<-function(first_block, last_block) {
#Have a code for assigning numbers to type of graphs we are interested in detecting 
#1: Is a Simple transaction 1 input 1 output
#2: Simple transaction with either one input and 2 outputs or vice verca with realted or unrelated addresses
#3: Islands Few Inputs Many Outputs  per transaction with Connected Addresses
#4: Islands with Many Inputs Few Outputs  per transaction with Connected Addresses
#5: Transactions Chains with leakages
#6: Transaction Chains without leakages
#7: Transaction Rings with leakage
#8: Transaction Rings without leakage
#9: Unclassified  
  g <- generate_graph(first_block)
  comb_graphs <- create_cluster_graphs(g, 20, first_block)
  decomped <- data.frame()
  cluster_list <- vector("list",length(comb_graphs))
  for (i in 1:length(comb_graphs)) {
    nice_plot(comb_graphs[[i]])
    n1<-readline(prompt="Enter skip 1: " )
    n1<-as.integer(n1)
    dec_cluster <- decompose(comb_graphs[[i]])
    island_list <- vector("list", length(dec_cluster))
   
      for (j in 1:length(dec_cluster)) {
        island_list[[j]] <-(dec_cluster[[j]])
        if(n1 == 0) {
          nice_plot(dec_cluster[[j]])
          n1<-readline(prompt="Enter skip 2: " )
          n1<-as.integer(n1)
          data <- cbind(as.data.frame(get_graph_info(dec_cluster[[j]])), cluster = i, island = j, block = first_block, n1)
          decomped <- rbind(decomped, data)
          n1 <- 0
        }else{
          data <- cbind(as.data.frame(get_graph_info(dec_cluster[[j]])), cluster = i, island = j, block = first_block, n1)
          decomped <- rbind(decomped, data)
        }
        cluster_list[[i]] <- island_list
      }
  }
  save(cluster_list, file = paste("cluster_islands_", first_block, ".RData", sep = ""))
  save.image()
  write.csv(decomped, file = paste("categorized_islands", first_block,".csv", sep = ""))
  return(decomped)

}
#takes a block to categorize and outputs a list containing the
#data frame holding the graph info of each island and a list of each igraph island.
bind_trained_data <- function() {
  files <- list.files("~/indv/", pattern="categorized_islands", full.names=TRUE)
  train <- do.call("rbind", lapply(files, read.csv))
  return(train[,-1])
}
prepare_test_data<- function(block_number) {
  g <- generate_graph(block_number)
  dg <- decompose(g, min.vertices = 20)
  g_info <- data.frame()
  for(i in 1:length(dg)) {
    row <- cbind(as.data.frame(get_graph_info(dg[[i]])),cluster = NA, island = i, block = block_number)
    
    g_info <- rbind(g_info,as.data.frame(row))
  }
  
  return (list(g_info, dg))

}

run_svm_pred <- function(learning_data, test_block) {
  learning_data <- bind_trained_data()
  train_sub <- learning_data[,c(1:6)]
  target <- as.factor(learning_data[,c("n1")])
  svm_model <- svm(train_sub, target) 
  p_test <- prepare_test_data(test_block)
  test <- p_test[[1]][,c(1:9)]
  for(i in 1:length(test[,1])) {
    pred <- predict(svm_model,test[i,1:6])
    nice_plot(p_test[[2]][[i]])
    print(pred)
    n1<-readline(prompt="Is the prediction correct: 0 (YES) 1 (NO):  " )
    n1<- as.integer(n1)
    if(n1 == 0) {
      row = as.data.frame(cbind(p_test[[1]][i,], n1 = pred))
      learning_data <- rbind(learning_data, row)
    }else{
      n1<-readline(prompt="Enter the correct assignement:  " )
      n1 <- as.integer(n1)
      row = as.data.frame(cbind(p_test[[1]][i,], n1 = pred))
      learning_data <- rbind(learning_data, row)
    }
  }
  write.csv(learning_data, file = "svm/svm_1_7.csv")
  return(learning_data)
}

learn_d <- bind_trained_data()
run_svm_pred(learn_d,36415)

library("e1071")
run_svm_pred(train[,-1], 364138)

train_sub <- train[,c(2:3,5:7)]
row = cbind(p_test[[1]][1,], n1 = pred)
rbind(train[,-1], p_test[[1]][1,])


