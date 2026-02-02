#!/bin/bash

user=$(id -u)
log_folder="/var/logs/shell-roboshop"
log_file="/var/logs/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$(pwd)
mongodb_host=mongodb.daws-88s.online

if [ $user -ne 0]; then
   echo -e "$R Please run this script with root user access $N" | tee -a $log_file
   exit 1
fi

mkdir -p $logs_folder

validate() {
    if [ $1 -ne 0]; then
       echo -e "$2 $R failed $N"  | tee -a $log_file
       exit 1
    else 
       echo -e "$2 $R success $N" | tee -a $log_file
    fi   
}

dnf module disable nodejs -y &>> $log_file
validate $? "disabling nodejs default module"

dnf module enable nodejs -y &>> $log_file
validate $? "enabling nodejs 20"

dnf install nodejs -y &>> $log_file
validate $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $log_file
   validate $? "Creating system user"
else
   echo "user already created"
fi      

mkdir -p /app 
validate $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $log_file
validate $? "downloading catalogue code"

cd /app 
validate $? "moving to app directory"

unzip /tmp/catalogue.zip &>> $log_file
validate $? "Unzip catalogue code"

npm install &>> $log_file
validate $? "downloading dependencies"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service &>> $log_file
validate $? "Created systemctl service"

systemctl daemon reload
validate $? "Loading the service"

systemctl enable catalogue
systemctl start catalogue &>> $log_file
validate $? "enabling and starting the service"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>> $log_file

index=$(mongosh --host $mongodb_host --quiet -eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $index -le 0 ]; then
   mongosh --host $mongodb_host </app/db/master-data.js
   validate $? "Loading Products"
else
   echo -e "Product already loaded..$Y Skipping $N" 
fi

systemctl restart catalogue
validate $? "restarting catalogue" 











