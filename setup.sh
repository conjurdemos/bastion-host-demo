#!/usr/bin/env bash

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

conjur policy load --as-group v4/developers --collection ${CF_STACK} policy.rb

layers=(
    conjurops:layer:$CF_STACK/bastion-host-demo/clientA
    conjurops:layer:$CF_STACK/bastion-host-demo/clientB
    conjurops:layer:$CF_STACK/bastion-host-demo/bastionServer
)

for i in "${layers[@]}"; do
    factory_name=`echo $i | awk -F'[:=]' '{print $3}'`_factory
    tokenLength=`conjur hostfactory show ${factory_name} | jsonfield 'tokens' | wc -c`
    if [ $tokenLength == '0' ]; then
        echo "Creating token for $factory_name"
        conjur hostfactory tokens create --duration-days 365 ${factory_name}
    fi

done