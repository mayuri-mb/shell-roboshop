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

dnf module disable nginx -y  &>>$logs_file
dnf module enable nginx:1.24 -y &>>$logs_file
dnf install nginx -y  &>>$logs_file
validate $? "Installing nginx"

systemctl enable nginx 
systemctl start nginx  &>>$logs_file
validate $? "enabled and started nginx"

rm -rf /usr/share/nginx/html/*   &>>$logs_file
validate $? "Remove existing data"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip  &>>$logs_file
validate $? "downloading frontend code"

cd /usr/share/nginx/html  &>>$logs_file
validate $? "moving to html folder"

unzip /tmp/frontend.zip  &>>$logs_file
validate $? "unzip code"

cp $script_dir/nginx.conf /etc/nginx/nginx.conf  &>>$logs_file
validate $? "copied nginx conf file"

systemctl restart nginx &>>$logs_file
validate $? "restarting nginx"



