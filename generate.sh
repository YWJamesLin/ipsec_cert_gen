#! /bin/bash
# Generate IPSec Certification
# 2015.09.24 Created By YWJamesLin
# 2016.01.09 Last Modified

IPSec_Program="ipsec"
StrongSwan_DIR="/etc"

KeyType="rsa"
KeySize="4096"

CAName="StrongSwanCA"
LeftName="Server"
RightName="Client"

CALifeTime="3650"
LeftLifeTime="3650"
RightLifeTime="3650"

Left_San_Flag_String="--flag serverAuth --flag ikeIntermediate"
Right_San_Flag_String=""

GenCA="1"
GenLeft="1"
GenRight="1"
GenTar="1"
GenP12="1"

cd ${StrongSwan_DIR}

if [ ${GenCA} == "1" ]; then
  ${IPSec_Program} pki --gen --type ${KeyType} --size ${KeySize} --outform pem > ipsec.d/private/${CAName}Key.pem
  chmod 600 ipsec.d/private/${CAName}Key.pem

  ${IPSec_Program} pki --self --ca --lifetime ${CALifeTime} --in ipsec.d/private/${CAName}Key.pem --type ${KeyType} --dn "C=NL, O=Example Organization, CN=strongswan Root CA" --outform pem > ipsec.d/cacerts/${CAName}Cert.pem

  ${IPSec_Program} pki --print --in ipsec.d/cacerts/${CAName}Cert.pem
fi

if [ ${GenLeft} == "1" ]; then
  ${IPSec_Program} pki --gen --type ${KeyType} --size ${KeySize} --outform pem > ipsec.d/private/${LeftName}Key.pem
  chmod 600 ipsec.d/private/${LeftName}Key.pem

  ${IPSec_Program} pki --pub --in ipsec.d/private/${LeftName}Key.pem --type ${KeyType} | ${IPSec_Program} pki --issue --lifetime ${LeftLifeTime} --cacert ipsec.d/cacerts/${CAName}Cert.pem --cakey ipsec.d/private/${CAName}Key.pem --dn "C=NL, O=Example Organization, CN=vpn.example.org" ${Left_San_Flag_String} --outform pem > ipsec.d/certs/${LeftName}Cert.pem

  ${IPSec_Program} pki --print --in ipsec.d/certs/${LeftName}Cert.pem
fi

if [ ${GenRight} == "1" ]; then
  ${IPSec_Program} pki --gen --type ${KeyType} --size ${KeySize} --outform pem > ipsec.d/private/${RightName}Key.pem
  chmod 600 ipsec.d/private/${RightName}Key.pem

  ${IPSec_Program} pki --pub --in ipsec.d/private/${RightName}Key.pem --type ${KeyType} | ${IPSec_Program} pki --issue --lifetime ${RightLifeTime} --cacert ipsec.d/cacerts/${CAName}Cert.pem --cakey ipsec.d/private/${CAName}Key.pem --dn "C=NL, O=Example Organization, CN=example@example.org" ${Right_San_Flag_String} --outform pem > ipsec.d/certs/${RightName}Cert.pem
  
  ${IPSec_Program} pki --print --in ipsec.d/certs/${RightName}Cert.pem
fi

if [ ${GenP12} == "1" ]; then
  openssl pkcs12 -export  -inkey ipsec.d/private/${RightName}Key.pem -in ipsec.d/certs/${RightName}Cert.pem -name "${RightName}'s VPN Certificate"  -certfile ipsec.d/cacerts/${CAName}Cert.pem -caname "strongswan Root CA" -out ~/${RightName}.p12
fi

if [ ${GenTar} == "1" ]; then
  tar zcvf ~/${RightName}_Linux.tar.gz ipsec.d/private/${RightName}Key.pem ipsec.d/certs/${RightName}Cert.pem ipsec.d/cacerts/${CAName}Cert.pem
fi
