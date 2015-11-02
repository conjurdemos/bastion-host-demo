#!/bin/bash

# Verify that the AWS command is installed

if [ ! -f /usr/local/bin/aws ]; then
    echo "AWS command not found!"
    exit
fi

CF_STACK='matt-TEST-bastion-demo'


###############################
##                           ##
## Write Code to:            ##
## Spin up environment in CF ##
##                           ##
###############################


# Get the Elastic IP for the host that is to be the Bastion

BASTION_EIP=`aws cloudformation list-stack-resources --stack-name ${CF_STACK} | grep demoEIP | awk '{print $4}'`
echo "Elastic IP Address for ${CF_STACK}: ${BASTION_EIP}"

# Get the internal IP for client A and client B

CLIENT_A_INSTANCE_ID=`aws cloudformation list-stack-resources --stack-name ${CF_STACK} | grep clientA | awk '{print $4}'`
CLIENT_A_IP=`aws ec2 describe-instances --instance-ids ${CLIENT_A_INSTANCE_ID} | grep NETWORKINTERFACES | awk '{print $6}'`
CLIENT_B_INSTANCE_ID=`aws cloudformation list-stack-resources --stack-name ${CF_STACK} | grep clientB | awk '{print $4}'`
CLIENT_B_IP=`aws ec2 describe-instances --instance-ids ${CLIENT_B_INSTANCE_ID} | grep NETWORKINTERFACES | awk '{print $6}'`

echo "Client A Internal IP Address: ${CLIENT_A_IP}"
echo "Client B Internal IP Address: ${CLIENT_B_IP}"


###############################
##                           ##
## Write Code to:            ##
## Conjurize environment     ##
##                           ##
###############################
## conjur host create bastion | tee host.json | conjurize --sudo --ssh | ssh ubuntu@${BASTION_EIP}
## conjur host create clientA | tee host.json | conjurize --sudo --ssh | ssh -tt ubuntu@${BASTION_EIP} bash -c ssh ubuntu@${CLIENT_A_IP}
## conjur host create clientB | tee host.json | conjurize --sudo --ssh | ssh -tt ubuntu@${BASTION_EIP} bash -c ssh ubuntu@${CLIENT_B_IP}

