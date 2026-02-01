#!/bin/bash

SG_ID="sg-0cfcd5040a31b76f2"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z0600999D8XNX0JXQIHH"
DOMAIN_NAME="daws-88s.online"

for instance in $@
do
    instance_id=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
             aws ec2 describe-instances \
             --instance-ids $instance_id \
             --query 'Reservations[].Instances[].PublicIpAddress' \
             --output text
        )
        RECORD_NAME="$DOMAIN_NAME"   #daws-88s.online
    else    
        IP=$(
            aws ec2 describe-instances \
             --instance-ids $instance_id \
             --query 'Reservations[].Instances[].PrivateIpAddress' \
             --output text
        )   
        RECORD_NAME="$instance.$DOMAIN_NAME"   #mongodb.daws-88s.online 
    fi

    echo "IP Address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
            "Comment": "Update record",
            "Changes": [
                {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$RECORD_NAME'",
                    "Type": "A",
                    "TTL": 1
                    "ResourceRecords": [
                        { "Value": "'$IP'" }
                    ]
                }
            }
        ]
    }'
    echo "Record updated for $instance"

done  
