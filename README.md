# bastion-host-demo

## To run:

./demo-setup.sh [arguments]

arguments:
-h, --help                    show brief help
--dns-name=DOMAIN_DNS_NAME    Domain DNS name to use in AWS
--keypair=AWS_KEY_PAIR        AWS KeyPair to use
--stack-name=CF_STACK_NAME     Cloud Formation Stack Name

Example:
```
./demo-setup.sh --stack-name=TEST-demo --keypair=demo --dns-name=demo.example.com
```