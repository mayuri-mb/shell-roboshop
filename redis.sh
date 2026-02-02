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

dnf module disable redis -y &>> $logs_file
dnf module enable redis:7 -y &>> $logs_file
validate $? "enabling redis:7"

dnf install redis -y &>> $logs_file
validate $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
validate $? "Allowing remote connections"

dnf enable redis -y &>> $logs_file
dnf start redis -y 
validate $? "ebaled and started redis"

