observed_data <- read.csv("//wsl.localhost/Ubuntu/home/ddeodato/tese/20251004/images_results/teste/shannon_obsservedFeatures/data/observed_features.csv", row.names=1)
iter_64k <- observed_data[,31:40]
avg_observed <- apply(iter_64k,1,mean, na.rm=T)
avg_observed
outputCSV <- observed_data[,101:106]
outputCSV["observed_features"] <- avg_observed
write.csv(outputCSV, "//wsl.localhost/Ubuntu/home/ddeodato/tese/20251004/images_results/teste/Metadata_observed_features.csv")
