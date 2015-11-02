#!/bin/bash

# Verify that the AWS command is installed
if [ ! -f /usr/local/bin/aws ]; then
    echo "AWS command not found!"
    exit 1
fi

if [ $# -gt 0 ]; then
	while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "$0 [arguments]"
                        echo " "
                        echo "arguments:"
                        echo "-h, --help                    show brief help"
                        echo "--dns-name=DOMAIN_DNS_NAME    Domain DNS name to use in AWS"
                        echo "--keypair=AWS_KEY_PAIR        AWS KeyPair to use"
                        echo "--stack-name=CF_STACK_NAME     Cloud Formation Stack Name"
                        exit 0
                        ;;
                --keypair*)
                        KEYPAIR_NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                --stack-name*)
                        CF_STACK=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                --dns-name*)
                        DOMAIN_DNS_NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                *)
                        echo "$0 [arguments]"
                        echo " "
                        echo "arguments:"
                        echo "-h, --help                    show brief help"
                        echo "--dns-name=DOMAIN_DNS_NAME    Domain DNS name to use in AWS"
                        echo "--keypair=AWS_KEY_PAIR        AWS KeyPair to use"
                        echo "--stack-name=CF_STACK_NAME     Cloud Formation Stack Name"
                        exit 1
                        ;;
        esac
    done
else
    echo "$0 [arguments]"
    echo " "
    echo "arguments:"
    echo "-h, --help                    show brief help"
    echo "--dns-name=DOMAIN_DNS_NAME    Domain DNS name to use in AWS"
    echo "--keypair=AWS_KEY_PAIR        AWS KeyPair to use"
    echo "--stack-name=CF_STACK_NAME     Cloud Formation Stack Name"
	exit 1
fi
BASTION_TEMPLATE=${PWD}'/bastion-demo-cf-template.json'

# Verify that script can find bastion demo CF template
if [ ! -f $BASTION_TEMPLATE ]; then
	echo 'CF Template not found!'
	exit 1
fi

echo ''
echo 'Spinning up a demo environment using AWS Cloudformation.'
echo 'CF Template being used:' $BASTION_TEMPLATE
echo 'CF Stack Name is:' $CF_STACK
echo 'AWS KeyPair being used:' $KEYPAIR_NAME
echo 'DomainDNSName being used:' $DOMAIN_DNS_NAME

###########################################
## Spin up environment in CloudFormation ##
###########################################
echo ''
STACK_ID=`aws cloudformation create-stack --stack-name ${CF_STACK} --template-body file://${BASTION_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${KEYPAIR_NAME} ParameterKey=DomainDNSName,ParameterValue=${DOMAIN_DNS_NAME}`
STATUS=`aws cloudformation describe-stacks --stack-name ${CF_STACK} | grep ${STACK_ID} | awk '{print $10}'`
while [[ $STATUS != "CREATE_COMPLETE" ]]
do
	echo 'Environment Creation Status:' $STATUS
	sleep 1m
    STATUS=`aws cloudformation describe-stacks --stack-name ${CF_STACK} | grep STACKS | awk '{print $10}'`
    #if [ $STATUS == "CREATE_FAILED"]; then
    #    echo 'Environment Creation Status:' $STATUS
    #    exit 1
    #fi
done

echo 'Environment Creation Status:' $STATUS
echo ''

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
echo ''
echo 'conjur host create bastion | tee host.json | conjurize --sudo --ssh | ssh ubuntu@'${BASTION_EIP}
echo 'conjur host create clientA | tee host.json | conjurize --sudo --ssh | ssh -tt ubuntu@'${BASTION_EIP}' bash -c ssh ubuntu@$'{CLIENT_A_IP}
echo 'conjur host create clientB | tee host.json | conjurize --sudo --ssh | ssh -tt ubuntu@'${BASTION_EIP}' bash -c ssh ubuntu@$'{CLIENT_B_IP}

