setwd("~/Documents/DataScience/caris");

mesi_data <- read.csv("mesi_data.csv",check.names=FALSE);
mesi_site_mapping <- read.csv("mesi_site_mapping.csv");
colnames(mesi_data)[3] <- "address";
colnames(mesi_data)[5] <- "telephone";
for(DPA in mesi_data){mesi_data$DPA_as_date<-as.Date(mesi_data$DPA, "%d/%m/%Y")};

mesi<-merge(mesi_data, mesi_site_mapping,by="hos_name");
head(mesi);

#DPA in last year
mesi_summary<- summary(mesi[as.Date(mesi$DPA, "%d/%m/%Y")>"2013-10-01" & as.Date(mesi$DPA, "%d/%m/%Y")<"2014-10-01" & mesi$FetusViable!="Non",]);

original_colname_list <- colnames(mesi); #to preserve
selected_cols <- c("city_code","hos_code","DPA_as_date","Nom Patient","address","Date Naissance","telephone","Code Service Prenatal","Nom Instituttion Suivi En Clinique Prenatale","FetusViable","DATE DECES FETUS PTME", "DATE PROPHYLAXIE FEMME AU TRAVAIL", "DATE CONFIRMEE ACCOUCHEMENT", "DATE ACCOUCHEMENT INSTITUTION","CODE ENROLEMENT ST", "CodeServicePrenatal")

#check if col is needed or not
for(col in selected_cols){ if(!(col %in% names(mesi))){print(col)}}

#mesi_filtered is list of needed_cols (after merge with Caris Site Codes)
mesi_filtered <- mesi[as.Date(mesi$DPA, "%d/%m/%Y")>"2013-10-01" & as.Date(mesi$DPA, "%d/%m/%Y")<"2014-10-01" & mesi$FetusViable!="Non" ,selected_cols]

head(mesi_filtered);