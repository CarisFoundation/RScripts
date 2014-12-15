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
selected_cols <- c("Code VCT","city_code","hos_code","DPA_as_date","Nom Patient","address","Date Naissance","telephone","Code Service Prenatal","Nom Instituttion Suivi En Clinique Prenatale","FetusViable","DATE DECES FETUS PTME", "DATE PROPHYLAXIE FEMME AU TRAVAIL", "DATE CONFIRMEE ACCOUCHEMENT", "DATE ACCOUCHEMENT INSTITUTION","CODE ENROLEMENT ST", "CodeServicePrenatal")

#check if col is needed or not
for(col in selected_cols){ if(!(col %in% names(mesi))){print(col)}}

#mesi_filtered is list of needed_cols (after merge with Caris Site Codes)
mesi_filtered <- mesi[as.Date(mesi$DPA, "%d/%m/%Y")>"2013-10-01" & as.Date(mesi$DPA, "%d/%m/%Y")<"2014-10-01" & mesi$FetusViable!="Non" ,selected_cols]

head(mesi_filtered);

#using wrong credentials, replace mysql credentials with original values
user = "root";
password = "root";
host="localhost";
db_name="caris_db";
library(RMySQL)
drv <- dbDriver("MySQL")
con <- dbConnect(drv, user=user, password=password, dbname=db_name, host=host);
query <- "select city_code, hospital_code, patient_number, patient_code, mereenfant_mother_info.*  
from patient,
(select id_patient, date as date_of_mereenfant_form,  mother_code, 
infant_dob, mother_enrolled_in_ptme  
from testing_mereenfant
where 
date>='2013-10-01' and date <'2014-10-01'
#and mother_code!=0
) as mereenfant_mother_info
where patient.id = mereenfant_mother_info.id_patient limit 500000";
query <- "select * from patients";



query <- "select city_code, hospital_code, patient_number, mereenfant_mother_info.mother_code  
from patient,
(select id_patient, date as date_of_mereenfant_form,  mother_code, 
infant_dob, mother_enrolled_in_ptme  
from testing_mereenfant
where 
date>='2013-10-01' and date <'2014-10-01'
and length(mother_code)>0
) as mereenfant_mother_info
where patient.id = mereenfant_mother_info.id_patient limit 500000";


rs <- dbSendQuery(con,query);
fetch(rs, n = 5);
mother_info_child_code <- fetch(rs,n=50000);
mother_info_child_code
nrow(mother_info_child_code)

matched_code <- mother_info_child_code$mother_code %in% mesi_filtered$CodeServicePrenatal & ;
mesi_filtered[matched_code,]

mesi_filtered


#Query to map with Caris's Data
query <- "SELECT Code_VCT,
       CODE_ENROLEMENT_ST,
       CodeServicePrenatal,
       hivhaiti_data.mother_code,
       hivhaiti_data.*,
       mesi_filtered.*
FROM
  (SELECT city_code,
          hospital_code,
          patient_number,
          patient_code,
          mereenfant_mother_info.*
   FROM patient,

     (SELECT id_patient,
             date AS date_of_mereenfant_form,
             mother_code,
             infant_dob,
             mother_enrolled_in_ptme
      FROM testing_mereenfant
      WHERE date>='2013-10-01'
        AND date <'2014-10-01'
        AND length(mother_code)>0) AS mereenfant_mother_info
   WHERE patient.id = mereenfant_mother_info.id_patient) hivhaiti_data,
                                                         mesi_filtered3 AS mesi_filtered
WHERE ((LOCATE(UPPER(hivhaiti_data.mother_code), UPPER(mesi_filtered.Code_VCT))
        AND ((length(hivhaiti_data.mother_code)/length(mesi_filtered.Code_VCT) >.5)))
       OR (LOCATE(UPPER(hivhaiti_data.mother_code), UPPER(mesi_filtered.CODE_ENROLEMENT_ST))
           AND ((length(hivhaiti_data.mother_code)/length(mesi_filtered.CODE_ENROLEMENT_ST) >.5)))
       OR (LOCATE(UPPER(hivhaiti_data.mother_code), UPPER(mesi_filtered.CodeServicePrenatal))
           AND ((length(hivhaiti_data.mother_code)/length(mesi_filtered.CodeServicePrenatal) >.5)))
       OR (LOCATE(UPPER(mesi_filtered.Code_VCT), UPPER(hivhaiti_data.mother_code))
           AND ((length(mesi_filtered.Code_VCT)/length(hivhaiti_data.mother_code) >.5)))
       OR (LOCATE(UPPER(mesi_filtered.CODE_ENROLEMENT_ST), UPPER(hivhaiti_data.mother_code))
           AND ((length(mesi_filtered.CODE_ENROLEMENT_ST)/length(hivhaiti_data.mother_code) >.5)))
       OR (LOCATE(UPPER(mesi_filtered.CodeServicePrenatal), UPPER(hivhaiti_data.mother_code))
           AND ((length(mesi_filtered.CodeServicePrenatal)/length(hivhaiti_data.mother_code) >.5))))
  AND hivhaiti_data.hospital_code=mesi_filtered.hos_code
  AND length(hivhaiti_data.mother_code)>2 ";


