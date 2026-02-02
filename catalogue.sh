#!/bin/bash

user=$(id -u)
logs_folder="/var/log/shell-roboshop"
logs_file="$logs_folder/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$pwd
mongodb_host=mongodb.daws-88s.online

if [ $user -ne 0 ]; then
   echo -e "$R Please run this script with root user access $N" | tee -a $logs_file
   exit 1
fi

mkdir -p $logs_folder

validate() {
    if [ $1 -ne 0 ]; then
       echo -e "$2 $R failed $N"  | tee -a $logs_file
       exit 1
    else 
       echo -e "$2 $R success $N" | tee -a $logs_file
    fi   
}

dnf module disable nodejs -y &>> $logs_file
validate $? "disabling nodejs default module"

dnf module enable nodejs:20 -y &>> $logs_file
validate $? "enabling nodejs 20"

dnf install nodejs -y &>> $logs_file
validate $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
   validate $? "Creating system user"
else
   echo -e "Roboshop user already exist..$Y Skipping $N"
fi      

mkdir -p /app 
validate $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $logs_file
validate $? "downloading catalogue code"

cd /app 
validate $? "moving to app directory"

rm -rf /app/*
validate $? "Removing existing code"

unzip /tmp/catalogue.zip &>> $logs_file
validate $? "Unzip catalogue code"

npm install &>> $logs_file
validate $? "downloading dependencies"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service &>> $logs_file
validate $? "Created systemctl service"

systemctl daemon reload
validate $? "Loading the service"

systemctl enable catalogue
systemctl start catalogue &>> $logs_file
validate $? "enabling and starting the service"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>> $logs_file

index=$(mongosh --host $mongodb_host --quiet -eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $index -le 0 ]; then
   mongosh --host $mongodb_host </app/db/master-data.js
   validate $? "Loading Products"
else
   echo -e "Product already loaded..$Y Skipping $N" 
fi

systemctl restart catalogue
validate $? "restarting catalogue" 











