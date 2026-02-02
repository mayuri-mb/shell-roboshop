#!/bin/bash

user=$(id -u)
logs_folder="/var/log/shell-roboshop"
logs_file="$logs_folder/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$PWD
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

dnf install python3 gcc python3-devel -y ?>>$logs_file
validate $? "installing Python"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$logs_file
   echo "Creating system user"
else
   echo -e "Roboshop user already exist $Y Skipping $N"
fi

mkdir -p /app  &>>$logs_file
validate $ "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$logs_file
validate $? "downloading payment code"

cd /app  &>>$logs_file
validate $? "moving to app directory"

rm -rf /app/*
validate "Removing existing code"

unzip /tmp/payment.zip &>>$logs_file
validate "unzip code"

cd /app 
pip3 install -r requirements.txt &>>$logs_file
validate $? "installing dependencies"

cp $script_dir/payment.service /etc/systemd/system/payment.service &>>$logs_file
validate $? "created systemctl service"

systemctl daemon-reload &>>$logs_file
validate $? "load the service"

systemctl enable payment 
systemctl start payment &>>$logs_file
validate $? "enabled and started paymant"


