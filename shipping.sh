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

dnf install maven -y &>>$logs_file
validate $? "installing maven"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$logs_file
   echo "Creating system user"
else
   echo -e "Roboshop user already exist $Y Skipping $N"
fi

mkdir -p /app &>>$logs_file
validate $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$logs_file
validate $? "copying shipping code"

cd /app &>>$logs_file
validate $? "moving to app directory"

rm -rf /app/*  &>>$logs_file
validate $? "removing existing code"

unzip /tmp/shipping.zip  &>>$logs_file
validate $? "unzip shipping code"

cd /app  
mvn clean package &>>$logs_file
validate $? "installing and building shipping"

mv target/shipping-1.0.jar shipping.jar 
validate $? "moving and renaming shipping"

cp $script_dir/shipping.service /etc/systemd/system/shipping.service &>>$logs_file
validate $? "creating system user"

systemctl daemon-reload
validate $? "load the service"

systemctl enable shipping
systemctl start shipping  &>>$logs_file
validate $? "enabled and started shipping"

dnf install mysql -y  &>>$logs_file
validate $? "installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then
   mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$logs_file
   mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$logs_file
   mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$logs_file
   validate $? "Loaded data into mysql"
else
   echo -e "Data is already loaded, $Y Skipping $N"
fi   

systemctl restart shipping  &>>$logs_file
validate $? "restarted shipping"



