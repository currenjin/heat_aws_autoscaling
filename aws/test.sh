#!/bin/bash

### Require to get Start ##########################
# 1. Should be Target Group of LoadBalancer
# 2. Should be Launch Configuration or Launch Template
# 3. Should be VPC Subnet
# 4. Should be Sign in AWS CLI
################################################

# Create AutoScaling Group and Add on Target of LoadBalancer
aws autoscaling create-auto-scaling-group --auto-scaling-group-name WEB-ASG \
	--launch-configuration-name ASG-Config \
	--vpc-zone-identifier "subnet-935a89f8,subnet-7870fc03,subnet-04f5f248" \
	--target-group-arns "arn:aws:elasticloadbalancing:ap-northeast-2:872934350981:targetgroup/Target/2f97ef1a2ea2bce2" \
	--max-size 3 --min-size 1 --desired-capacity 1

### Threshold < 15% = instance -1
aws autoscaling put-scaling-policy \
	--auto-scaling-group-name WEB-ASG \
	--policy-name DOWN-Policy \
	--adjustment-type ChangeInCapacity \
	--scaling-adjustment -1 \
	--cooldown 60 > ./arn.txt

# Cut to ARN for CloudWatch Alarm
arn=`head -n 2 arn.txt | tail -1 | cut -f 4 -d '"'`
aws cloudwatch put-metric-alarm \
--alarm-name DOWN-Alarm \
--metric-name CPUUtilization \
--namespace AWS/EC2 \
--statistic Average \
--period 300 \
--threshold 15 \
--comparison-operator LessThanOrEqualToThreshold \
--dimensions Name=AutoScalingGroupName,Value=WEB-ASG \
--evaluation-periods 1 \
--alarm-actions $arn

### Threshold < 70% = instance +1
aws autoscaling put-scaling-policy \
	--auto-scaling-group-name WEB-ASG \
	--policy-name UP-Policy \
	--adjustment-type ChangeInCapacity \
	--scaling-adjustment 1 \
	--cooldown 60 > ./arn.txt

# Cut to ARN for CloudWatch Alarm
arn=`head -n 2 arn.txt | tail -1 | cut -f 4 -d '"'`
aws cloudwatch put-metric-alarm \
--alarm-name UP-Alarm \
--metric-name CPUUtilization \
--namespace AWS/EC2 \
--statistic Average \
--period 300 \
--threshold 70 \
--comparison-operator GreaterThanOrEqualToThreshold \
--dimensions Name=AutoScalingGroupName,Value=WEB-ASG \
--evaluation-periods 1 \
--alarm-actions $arn
