#/bin/bash


# Script creates an application based on 4 VM's: web0, web1, sql0, sql1
# From network infrastructure perspective it creates router (router-01)
# connected to external GW (public network) and two networks:
# public-network-01 and private-network-01 
#

#APP_NAME="app_name"
HEAT_TEMPLATE_FILE="heat_template_$APP_NAME.yaml"
TEMPLATE_VERSION=$(date +%Fd%Mm%Ss)
# neutron net-external-list
ROUTER_GW_NET_ID="0653fccb-ec62-4241-9c4c-c3209de43ed2"
# nova keypair-list
INSTANCE_KEY_NAME="sgkp-ccs"
# nova image-list
IMAGE_ID="f6228720-60a1-4f34-824f-1c2ca5b45ee3"

echo "Please provide application name: (eq: APP_01)"
read APP_NAME

if [ -f $HEAT_TEMPLATE_FILE ];
then
        echo "Removing existing HEAT template file and creating new one: $HEAT_TEMPLATE_FILE"
        rm -f $HEAT_TEMPLATE_FILE
else
        echo "Creating new HEAT template file: $HEAT_TEMPLATE_FILE"
fi

#Template header

cat > $HEAT_TEMPLATE_FILE<<EOF
description: Heat template to create application $APP_NAME
heat_template_version: $TEMPLATE_VERSION
resources:
EOF

#Network part

cat >> $HEAT_TEMPLATE_FILE<<EOF
  $APP_NAME-private-network-01:
    properties: {admin_state_up: true, name: $APP_NAME-private-network-01}
    type: OS::Neutron::Net
  $APP_NAME-private-subnet-01:
    properties:
      cidr: 192.168.2.0/24
      enable_dhcp: true
      gateway_ip: 192.168.2.1
      name: $APP_NAME-private-subnet-01
      network_id: {get_resource: $APP_NAME-private-network-01}
    type: OS::Neutron::Subnet
  $APP_NAME-public-network-01:
    properties: {admin_state_up: true, name: $APP_NAME-public-network-01}
    type: OS::Neutron::Net
  $APP_NAME-public-subnet-01:
    properties:
      cidr: 192.168.1.0/24
      enable_dhcp: true
      gateway_ip: 192.168.1.1
      name: $APP_NAME-public-subnet-01
      network_id: {get_resource: $APP_NAME-public-network-01}
    type: OS::Neutron::Subnet
  $APP_NAME-router-01:
    properties: {admin_state_up: true, name: $APP_NAME-router-01}
    type: OS::Neutron::Router
  $APP_NAME-router-01-gw:
    properties:
      network_id: $ROUTER_GW_NET_ID
      router_id: {get_resource: $APP_NAME-router-01}
    type: OS::Neutron::RouterGateway
  $APP_NAME-router-int0:
    properties:
      router_id: {get_resource: $APP_NAME-router-01}
      subnet_id: {get_resource: $APP_NAME-public-subnet-01}
    type: OS::Neutron::RouterInterface
  $APP_NAME-router-int1:
    properties:
      router_id: {get_resource: $APP_NAME-router-01}
      subnet_id: {get_resource: $APP_NAME-private-subnet-01}
    type: OS::Neutron::RouterInterface
EOF


#VM part
cat >> $HEAT_TEMPLATE_FILE<<EOF
  $APP_NAME-sql0:
    properties:
      flavor: GP-Small
      image: $IMAGE_ID
      key_name: $INSTANCE_KEY_NAME
      name: $APP_NAME-sql-01
      networks:
      - port: {get_resource: $APP_NAME-sql0-port0}
    type: OS::Nova::Server
  $APP_NAME-sql0-port0:
    properties:
      admin_state_up: true
      network_id: {get_resource: $APP_NAME-private-network-01}
    type: OS::Neutron::Port
  $APP_NAME-sql1:
    properties:
      flavor: GP-Small
      image: $IMAGE_ID
      key_name: $INSTANCE_KEY_NAME
      name: $APP_NAME-sql-02
      networks:
      - port: {get_resource: $APP_NAME-sql1-port0}
    type: OS::Nova::Server
  $APP_NAME-sql1-port0:
    properties:
      admin_state_up: true
      network_id: {get_resource: $APP_NAME-private-network-01}
    type: OS::Neutron::Port
  $APP_NAME-web0:
    properties:
      flavor: GP-Small
      image: $IMAGE_ID
      key_name: $INSTANCE_KEY_NAME
      name: $APP_NAME-web-01
      networks:
      - port: {get_resource: $APP_NAME-web0-port0}
    type: OS::Nova::Server
  $APP_NAME-web0-port0:
    properties:
      admin_state_up: true
      network_id: {get_resource: $APP_NAME-public-network-01}
    type: OS::Neutron::Port
  $APP_NAME-web1:
    properties:
      flavor: GP-Small
      image: $IMAGE_ID
      key_name: $INSTANCE_KEY_NAME
      name: $APP_NAME-web-02
      networks:
      - port: {get_resource: $APP_NAME-web1-port0}
    type: OS::Nova::Server
  $APP_NAME-web1-port0:
    properties:
      admin_state_up: true
      network_id: {get_resource: $APP_NAME-public-network-01}
    type: OS::Neutron::Port
EOF

echo "Creating new stack: $APP_NAME"
heat stack-create -f $HEAT_TEMPLATE_FILE $APP_NAME

