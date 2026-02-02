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

dnf install mysql-server -y &>>$logs_file
validate $? "installing mysql"

systemctl enable mysqld &>> $logs_file
validate $? "enabling mysql"

systemctl start mysqld  &>> $logs_file
validate $? "starting mysql"

#get the password from user
mysql_secure_installation --set-root-pass RoboShop@1
validate $? "setup root password"

