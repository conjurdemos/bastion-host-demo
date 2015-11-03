# bastion-host-demo

## To run:

./demo-setup.sh [arguments]

arguments:<br>
-h, --help                    show brief help<br>
--dns-name=DOMAIN_DNS_NAME    Domain DNS name to use in AWS<br>
--keypair=AWS_KEY_PAIR        AWS KeyPair to use<br>
--stack-name=CF_STACK_NAME     Cloud Formation Stack Name<br>

Example:<br>
```
./demo-setup.sh --stack-name=TEST-demo --keypair=demo --dns-name=demo.example.com
```