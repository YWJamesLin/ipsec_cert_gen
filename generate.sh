#! /bin/bash
# Generate IPSec Certification
# 2015.09.24 Created By YWJamesLin

IPSec_Program="ipsec"
KeyType="rsa"
KeySize="4096"
StrongSwan_DIR="/usr/local/etc"
Server_San_Flag_String="--flag serverAuth --flag ikeIntermediate"
Client_San_Flag_String=""
cd ${StrongSwan_DIR}
ClientName="Client"

${IPSec_Program} pki --gen --type ${KeyType} --size ${KeySize} --outform der > ipsec.d/private/strongswanKey.der
chmod 600 ipsec.d/private/strongswanKey.der

${IPSec_Program} pki --self --ca --lifetime 3650 --in ipsec.d/private/strongswanKey.der --type ${KeyType} --dn "C=NL, O=Example Company, CN=strongswan Root CA" --outform der > ipsec.d/cacerts/strongswanCert.der

${IPSec_Program} pki --print --in ipsec.d/cacerts/strongswanCert.der

${IPSec_Program} pki --gen --type ${KeyType} --size ${KeySize} --outform der > ipsec.d/private/vpnHostKey.der
chmod 600 ipsec.d/private/vpnHostKey.der

${IPSec_Program} pki --pub --in ipsec.d/private/vpnHostKey.der --type ${KeyType} | ${IPSec_Program} pki --issue --lifetime 730 --cacert ipsec.d/cacerts/strongswanCert.der --cakey ipsec.d/private/strongswanKey.der --dn "C=NL, O=Example Company, CN=vpn.example.org" ${Server_San_Flag_String} --outform der > ipsec.d/certs/vpnHostCert.der

${IPSec_Program} pki --print --in ipsec.d/certs/vpnHostCert.der

${IPSec_Program} pki --gen --type ${KeyType} --size ${KeySize} --outform der > ipsec.d/private/${ClientName}Key.der
chmod 600 ipsec.d/private/${ClientName}Key.der

${IPSec_Program} pki --pub --in ipsec.d/private/${ClientName}Key.der --type ${KeyType} | ${IPSec_Program} pki --issue --lifetime 730 --cacert ipsec.d/cacerts/strongswanCert.der --cakey ipsec.d/private/strongswanKey.der --dn "C=NL, O=Example Company, CN=john@example.org" ${Client_San_Flag_String} --outform der > ipsec.d/certs/${ClientName}Cert.der

openssl ${KeyType} -inform DER -in ipsec.d/private/${ClientName}Key.der -out ipsec.d/private/${ClientName}Key.pem -outform PEM
openssl x509 -inform DER -in ipsec.d/certs/${ClientName}Cert.der -out ipsec.d/certs/${ClientName}Cert.pem -outform PEM
openssl x509 -inform DER -in ipsec.d/cacerts/strongswanCert.der -out ipsec.d/cacerts/strongswanCert.pem -outform PEM

openssl pkcs12 -export  -inkey ipsec.d/private/${ClientName}Key.pem -in ipsec.d/certs/${ClientName}Cert.pem -name "${ClientName}'s VPN Certificate"  -certfile ipsec.d/cacerts/strongswanCert.pem -caname "strongswan Root CA" -out ${ClientName}.p12
