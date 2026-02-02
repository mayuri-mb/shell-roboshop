#!/bin/bash

userid=$(id -u)
logs_folder="/var/logs/shell-roboshop"
logs_file="$logs_folder/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$PWD

if [ $userid -ne 0 ]; then
   echo -e "$R Please run this script with root access $N" | tee -a $logs_file
   exit 1
fi

mkdir -p $logs_folder

validate() {
    if [ $1 -ne 0 ]; then
       echo -e "$2 $R failed $N"  | tee -a $logs_file
       exit 1
    else
       echo -e "$2 $G success $N" | tee -a $logs_file
    fi
}

dnf module disable nodejs -y &>> $logs_file
validate $? "disabling nodejs default module"

dnf module enable nodejs:20 -y &>> $logs_file
validate $? "enabling nodejs:20 module"

dnf install nodejs -y &>> $logs_file
validate $? "installing nodejs"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
   echo "created system user"
else
   echo "Roboshop user already exist, $Y Skipping $N"
fi

mkdir -p /app
validate $? "creating app directory"

curl -l -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>> $logs_file
validate $? "downloading user code"

cd /app
validate $? "moving to app directory"

rm -rf /app/*   &>> $logs_file
validate $? "removing existing code"

unzip /tmp/user.zip  &>> $logs_file
validate $? "unzip user code"

npm install &>> $logs_file
validate $? "installing dependencies"

cp $script_dir/user.service /etc/systemd/system/user.service &>> $logs_file

systemctl daemon-reload

systemctl enable user 
systemctl start user &>> $logs_file
validate $? "enabled and started the User"




