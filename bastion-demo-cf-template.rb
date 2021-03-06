#!/usr/bin/env ruby

require 'cloudformation-ruby-dsl/cfntemplate'

template do

    value :AWSTemplateFormatVersion => '2010-09-09'

    value :Description => 'Conjur Bastion Demo Template'

    parameter 'KeyName',
        :Description => 'Name of an existing EC2 KeyPair to enable SSH access to the instance',
        :Type => 'AWS::EC2::KeyPair::KeyName',
        :Default => 'jenkins-user',
        :ConstraintDescription => 'must be the name of an existing EC2 KeyPair.'

    parameter 'InstanceType',
        :Description => 'Amazon EC2 instance type',
        :Type => 'String',
        :Default => 't2.micro',
        :AllowedValues => %w(t2.micro m3.medium m3.large m3.xlarge),
        :ConstraintDescription => 'must be a valid EC2 instance type.'

    parameter 'DomainDNSName',
        :Description => 'Fully qualified domain name (FQDN) of the forest root domain e.g. corp.example.com',
        :Type => 'String',
        :MinLength => 3,
        :MaxLength => 25,
        :AllowedPattern => '[a-zA-Z0-9]+\\..+'

    parameter 'VpcCidr',
        :Description => 'CIDR address for the VPC to be created.',
        :Type => 'String',
        :Default => '10.0.0.0/16'

    parameter 'bastionHostFactoryToken',
        :Description => 'Bastion Host-Factory Token',
        :Type => 'String'

    parameter 'clientAHostFactoryToken',
        :Description => 'clientA Host-Factory Token',
        :Type => 'String'

    parameter 'clientBHostFactoryToken',
        :Description => 'clientB Host-Factory Token',
        :Type => 'String'

    resource 'conjurBastionServer', :Type => 'AWS::EC2::Instance', :Properties => {
        :KeyName => ref('KeyName'),
        :ImageId => 'ami-d05e75b8',
        :InstanceType => ref('InstanceType'),
        :SecurityGroupIds => ref('BastionNATSG'),
        :SubnetId => ref('PublicSubnet'),
        :SourceDestCheck => 'false',
        # Loads an external userdata script.
        :UserData => base64(interpolate(file('userdata.sh'), tName: 'conjurBastionHostFactoryToken'))
    }

    resource 'conjurVPC', :Type => 'AWS::EC2::VPC', :Properties => {
        :CidrBlock => '10.0.0.0/16',
        :InstanceTenancy => 'default',
        :EnableDnsSupport => 'true',
        :EnableDnsHostnames => 'true'
    }

    resource 'clientA', :Type => 'AWS::EC2::Instance', :Properties => {
        :KeyName => ref('KeyName'),
        :InstanceType => 't2.micro',
        :ImageId => 'ami-d05e75b8',
        :SubnetId => ref('PublicSubnet'),
        :SecurityGroupIds => ref('vpnPrivateSG'),
        # Loads an external userdata script.
        :UserData => base64(interpolate(file('userdata.sh'), tName: 'clientAHostFactoryToken'))
    }, :DependsOn => ['conjurBastionServer']

    resource 'clientB', :Type => 'AWS::EC2::Instance', :Properties => {
        :KeyName => ref('KeyName'),
        :InstanceType => 't2.micro',
        :ImageId => 'ami-d05e75b8',
        :SubnetId => ref('PublicSubnet'),
        :SecurityGroupIds => ref('vpnPrivateSG'),
        # Loads an external userdata script.
        :UserData => base64(interpolate(file('userdata.sh'), tName: 'clientBHostFactoryToken'))
    }, :DependsOn => ['conjurBastionServer']

    resource 'VGWA6CCR', :Type => 'AWS::EC2::VPCGatewayAttachment', :Properties => {
        :InternetGatewayId => ref('InternetGateway'),
        :VpcId => ref('conjurVPC')
    }

    resource 'SUBRTE3D3G2', :Type => 'AWS::EC2::SubnetRouteTableAssociation', :Properties => {
        :RouteTableId => ref('RouteTable'),
        :SubnetId => ref('PublicSubnet')
    }

    resource 'InternetGateway', :Type => 'AWS::EC2::InternetGateway', :Properties => {
    }

    resource 'PublicSubnet', :Type => 'AWS::EC2::Subnet', :Properties => {
        :VpcId => ref('conjurVPC'),
        :CidrBlock => '10.0.0.0/24'
    }

    resource 'Route', :Type => 'AWS::EC2::Route', :Properties => {
        :RouteTableId => ref('RouteTable'),
        :DestinationCidrBlock => '0.0.0.0/0',
        :GatewayId => ref('InternetGateway')
    }, :DependsOn => [ 'VGWA6CCR' ]

    resource 'RouteTable', :Type => 'AWS::EC2::RouteTable', :Properties => {
        :VpcId => ref('conjurVPC')
    }

    resource 'demoEIP', :Type => 'AWS::EC2::EIP', :Properties => {
        :Domain => 'vpc',
        :InstanceId => ref('conjurBastionServer')
    }, :DependsOn => [ 'VGWA6CCR' ]

    resource 'BastionNATSG', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
        :GroupDescription => 'Enable NAT',
        :SecurityGroupIngress => [
            {
                :IpProtocol => 'tcp',
                :FromPort => '22',
                :ToPort => '22',
                :CidrIp => '0.0.0.0/0'
            },
            {
                :IpProtocol => '-1',
                :FromPort => '0',
                :ToPort => '65535',
                :CidrIp => ref('VpcCidr')
            }
        ],
        :VpcId => ref('conjurVPC'),
        :SecurityGroupEgress => [
            {
                :IpProtocol => '-1',
                :FromPort => '0',
                :ToPort => '65535',
                :CidrIp => '0.0.0.0/0'
            }
        ]
    }

    resource 'vpnPrivateSG', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
        :GroupDescription => 'Enable SSH access',
        :SecurityGroupIngress => [
            {
                :IpProtocol => 'tcp',
                :FromPort => '22',
                :ToPort => '22',
                :CidrIp => '0.0.0.0/0'
            }
        ],
        :VpcId => ref('conjurVPC')
    }

end.exec!