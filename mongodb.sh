#!/bin/bash

userid=$(id -u)
logs_folder="/var/logs/shell-roboshop"
logs_file="$logs_folder/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


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

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "copying mongo repo"

dnf install mongodb-org -y
validate $? "Installing mongodb server"

systemctl enable mongod
validate $? "Enable mongodb"

systemctl start mongod
validate $? "Start mongodb"
 
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf 
validate $? "Allowing remote connections"

systemctl restart mongod
validate $? "Restarted mongodb"


