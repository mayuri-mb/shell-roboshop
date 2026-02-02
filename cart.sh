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

dnf module disable nodejs -y  &>>$logs_file
validate $? "disabling nodejs default module"
dnf module enable nodejs:20 -y &>>$logs_file
validate $? "enabling nodejs:20"

dnf install nodejs -y &>>$logs_file
validate $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file 
   echo "creating system user"
else
   echo "Roboshop user already exist"
fi

mkdir -p /app
validate $? "creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$logs_file
validate $? "downloading cart code"

cd /app
validate $? "moving to app directory" 

rm -rf /app/*  &>>$logs_file
validate $? "removing existing code"

unzip /tmp/cart.zip  &>>$logs_file
validate $? "unzip cart code"

npm install  &>>$logs_file
validate $? "installing dependencies"

cp $script_dir/cart.service /etc/systemd/system/cart.service &>>$logs_file
validate $? "Creating systemctl service"

systemctl daemon-reload
validate $? "Loading the service"

systemctl enable cart &>>$logs_file
systemctl start cart  
validate $? "enabled and started cart"
