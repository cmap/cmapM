## entmoot A Randomforest classifier for plate quality

library('randomForest')

## Inputs
args <- commandArgs(T);
## BFPT file
filePath <- args[1];
## Output path
outDir <- args[2];
## Output filename
outName <- args[3];
## Path to this script, needed to load random forest dataset
scriptPath <- args[4];

cat(filePath, outDir, outName, scriptPath, '\n')

## Load Files
bfpt <- read.table(filePath,header=TRUE,sep="\t");
print('Read BFPT report')
if (bfpt$count_mean>0 & bfpt$plate_iqr != -666 & bfpt$avg_ss != -666 &
      bfpt$frac_good_qcode != -666 & bfpt$n_failed_wells != -666 & 
      bfpt$plate_flogp != -666 & bfpt$plate_slope != -666 & bfpt$span_plate!=-666 &
      bfpt$range_plate != -666 & bfpt$span_a02==-666 & bfpt$span_b02 == -666 &
      bfpt$bratio_measured>0 & bfpt$bratio_expected > 0 ) {
  bfpt$bratio_norm_score <-abs(bfpt$bratio_measured-bfpt$bratio_expected)/bfpt$bratio_expected;
  load(paste(scriptPath,'/entmoot_no_a02_b02.RData', sep=''))
  print('Random forest successfully loaded.')
  print('Using no_span model')
  
  ## Classify New Samples With Random Forest
  print("Classifying samples")
  tmp <- predict(r,newdata=bfpt,type="vote",norm.votes=T)
  bfpt$entmoot_score <- tmp[,2]
  bfpt$entmoot_pass <- predict(r,newdata=bfpt,type="class") 
  
} else if (bfpt$count_mean<=0 | bfpt$plate_iqr == -666 | bfpt$avg_ss == -666 |
    bfpt$frac_good_qcode == -666 | bfpt$n_failed_wells == -666 | 
    bfpt$plate_flogp == -666 | bfpt$plate_slope == -666 | bfpt$span_plate==-666|
    bfpt$range_plate==-666 | bfpt$span_a02==-666 | bfpt$span_b02 == -666 |
    bfpt$bratio_measured<=0| bfpt$bratio_expected<=0) {
  bfpt$bratio_norm_score <- -666
  bfpt$entmoot_score <- -666
  bfpt$entmoot_pass <- -666
  print('Missing values in BFPT, skipping entmoot')
} else {
  bfpt$bratio_norm_score <-abs(bfpt$bratio_measured-bfpt$bratio_expected)/bfpt$bratio_expected
  ## hack for fieldname change
  # bfpt$failed_wells <- bfpt$n_failed_wells
  load(paste(scriptPath,'/entmoot.RData', sep=''))
  print('Random forest successfully loaded.')
    
  ## Classify New Samples With Random Forest
  print("Classifying samples")
  tmp <- predict(r,newdata=bfpt,type="vote",norm.votes=T)
  bfpt$entmoot_score <- tmp[,2]
  bfpt$entmoot_pass <- predict(r,newdata=bfpt,type="class")
  # check if core cell line and fingerpint failed. if so, fail plate
  core_cells <- c("A375", "A549", "HCC515", "HEPG2", "HT29", "MCF7", "PC3", "VCAP")
  labeled_cell_id <- as.character(bfpt$cell_id)[1]
  fp_cell_id <- as.character(bfpt$fp_cell_line)[1]
  if (labeled_cell_id %in% core_cells & fp_cell_id != labeled_cell_id) {  
    bfpt$entmoot_pass <- 0
    write(fp_cell_id, file=paste(outDir, "POTENTIAL_CELL_LINE_MISLABEL.txt", sep="/"), ncolumns=1)
    cat("ENTMOOT FAILURE: possible cell line mixup\n")
  }
}
print("Writing out Entmoot Table.")
write.table(bfpt,sep='\t',file=paste(outDir,outName,sep='/'),row.names=F,quote=F)  



# bfpt.clean <- subset(bfpt, !(bfpt$count_mean<=0 | bfpt$plate_iqr == -666 | bfpt$avg_ss == -666 |
#   bfpt$frac_good_qcode == -666 | bfpt$failed_wells == -666 | 
#   bfpt$plate_flogp == -666 | bfpt$plate_slope == -666 | bfpt$span_plate==-666|
#   bfpt$range_plate==-666 | bfpt$span_a02==-666 | bfpt$span_b02 == -666 |
#   bfpt$bratio_measured<=0| bfpt$bratio_expected<=0) )
# 
# # missing span plates
# # label tossed plates, write list to file
# tossed.plates <- subset(bfpt, (bfpt$count_mean<=0 | bfpt$plate_iqr == -666 | bfpt$avg_ss == -666 |
#   bfpt$frac_good_qcode == -666 | bfpt$failed_wells == -666 | 
#   bfpt$plate_flogp == -666 | bfpt$plate_slope == -666 | bfpt$span_plate==-666|
#   bfpt$range_plate==-666 | bfpt$span_a02==-666 | bfpt$span_b02 == -666 |
#   bfpt$bratio_measured<=0| bfpt$bratio_expected<=0) )
# tossed.plates$bratio_norm_score <- -666;
# tossed.plates$entmoot_score <- -666;
# tossed.plates$entmoot_pass <- as.factor(-666);
# 
# # capture back some of the missing data plates
# recapture.plates <- subset(tossed.plates,!(tossed.plates$count_mean<=0 | tossed.plates$plate_iqr == -666 |
#   tossed.plates$avg_ss == -666 | tossed.plates$frac_good_qcode == -666 | 
#   tossed.plates$failed_wells == -666 | tossed.plates$plate_flogp == -666 |
#   tossed.plates$plate_slope == -666 | tossed.plates$span_plate==-666 |
#   tossed.plates$range_plate==-666 | tossed.plates$bratio_measured<=0 |
#   tossed.plates$bratio_expected<=0))
# recapture.plates$bratio_norm_score <- abs(recapture.plates$bratio_measured-
#   recapture.plates$bratio_expected)/recapture.plates$bratio_expected;
# recapture.plates$span_a02 <- mean(bfpt.clean$span_a02)
# recapture.plates$span_b02 <- mean(bfpt.clean$span_b02) 
# write.table(recapture.plates$det_plate,file=paste(outDir,'missing_span_plates.txt',sep='/'),
#             row.names=F,quote=F,col.names=F)
# 
# tossed.plates <- subset(tossed.plates,(tossed.plates$count_mean<=0 | tossed.plates$plate_iqr == -666 |
#   tossed.plates$avg_ss == -666 | tossed.plates$frac_good_qcode == -666 | 
#   tossed.plates$failed_wells == -666 | tossed.plates$plate_flogp == -666 |
#   tossed.plates$plate_slope == -666 | tossed.plates$span_plate==-666 |
#   tossed.plates$range_plate==-666 | tossed.plates$bratio_measured<=0 |
#   tossed.plates$bratio_expected<=0))
# write.table(tossed.plates$det_plate,sep='\t',
#             file=paste(outDir,'unclassified_plates.txt',sep='/'),
#             row.names=F,quote=F,col.names=F)

# bfpt.clean$bratio_norm_score <-abs(bfpt.clean$bratio_measured-bfpt.clean$bratio_expected)/bfpt.clean$bratio_expected;
# load('/cmap/data/scripts/sieve//entmoot/entmoot.RData')
# print('Random forest successfully loaded.')
# 
# # Classify New Samples With Random Forest
# print("Classifying samples")
# tmp <- predict(r,newdata=bfpt.clean,type="vote",norm.votes=T)
# bfpt.clean$entmoot_score <- tmp[,2]
# bfpt.clean$entmoot_pass <- predict(r,newdata=bfpt.clean,type="class")
# 
# # Classify Recaptured Plates
# tmp <- predict(r,newdata=recapture.plates,type="vote",norm.votes=T)
# recapture.plates$entmoot_score <- tmp[,2]
# recapture.plates$entmoot_pass <- predict(r,newdata=recapture.plates,
#                                          type="class")

# Write Failed Plates to Output Directory
# ented_bfpt <- rbind(bfpt.clean,recapture.plates)
# failed_plates <- data.frame(ented_bfpt$det_plate[ented_bfpt$entmoot_pass == 0])
# write.table(failed_plates,sep='\t',
#             file=paste(outDir,'failed_plates.txt',sep='/'),
#             row.names=F,quote=F,col.names=F)
# 
# # Save File, Write to Output Directory
# final_bfpt <- rbind(ented_bfpt,tossed.plates);
# write.table(final_bfpt,sep='\t',file=paste(outDir,outName,sep='/'),row.names=F,quote=F)
# 
# tryCatch({
#   print('ehllo');
#   print('goodbye');
# },error=function(e) print('shit'))

