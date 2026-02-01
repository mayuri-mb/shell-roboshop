#!/bin/bash

SG_ID="sg-0cfcd5040a31b76f2"
AMI_ID="ami-0220d79f3f480ecf5"

for instance i $@
do
    instance_id = $( aws ec2 run-instances \
    --image-id $AMI_ID \        # Replace with your AMI ID
    --instance-type "t3.micro" \  # Replace with your instance type
    --security-group-ids $SG_ID \ # Replace with your SG ID
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        Ip=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PublicIpAddress' \ 
            --output text
        )
    else    
        Ip=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PrivateIpAddress' \ 
            --output text
        )    
    fi
done  
