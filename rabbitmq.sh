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
MYSQL_HOST=mysql.daws-88s.online

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

cp $script_dir/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$logs_file
validate $? "added rabitmq repo"

dnf install rabbitmq-server -y &>>$logs_file
validate $? "installing rabbitmq"

systemctl enable rabbitmq-server &>>$logs_file
systemctl start rabbitmq-server &>>$logs_file
validate $? "enabled and started rabbitmq"

rabbitmqctl add_user roboshop roboshop123 &>>$logs_file
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"  &>>$logs_file
validate $? "created users and given permissions" 