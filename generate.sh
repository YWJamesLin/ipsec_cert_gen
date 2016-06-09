#! /bin/bash
# Generate IPSec Certification
# 2015.09.24 Created By YWJamesLin
# 2016.01.09 Last Modified

IpsecProgram="ipsec"
StrongSwanDir="/etc"

KeyType="ecdsa"
KeySize="521"

CAName="StrongSwanCA"
LeftName="Server"
RightName="Client_${LeftName}"

Country="TW"
Organization="Organization"
CASubjectName="C=${Country}, O=${Organization}, CN=${CAName}"
LeftSubjectName="C=${Country}, O=${Organization}, CN=${LeftName}"
RightSubjectName="C=${Country}, O=${Organization}, CN=${RightName}"

CALifeTime="3650"
LeftLifeTime="3650"
RightLifeTime="3650"

CASanFlagString=""
LeftSanFlagString="--flag serverAuth --flag ikeIntermediate"
RightSanFlagString="--san ${RightName}"

GenCA="1"
GenLeft="1"
GenRight="1"
GenTar="1"
GenP12="1"

cd ${StrongSwanDir}

if [ ${GenCA} == "1" ]; then
  ${IpsecProgram} pki --gen --type ${KeyType} --size ${KeySize} --outform pem > ipsec.d/private/${CAName}Key.pem
  chmod 600 ipsec.d/private/${CAName}Key.pem

  ${IpsecProgram} pki --self --ca --lifetime ${CALifeTime} --in ipsec.d/private/${CAName}Key.pem --type ${KeyType} --dn "${CASubjectName}" ${CASanFlagString} --outform pem > ipsec.d/cacerts/${CAName}Cert.pem

  ${IpsecProgram} pki --print --in ipsec.d/cacerts/${CAName}Cert.pem
fi

if [ ${GenLeft} == "1" ]; then
  ${IpsecProgram} pki --gen --type ${KeyType} --size ${KeySize} --outform pem > ipsec.d/private/${LeftName}Key.pem
  chmod 600 ipsec.d/private/${LeftName}Key.pem

  ${IpsecProgram} pki --pub --in ipsec.d/private/${LeftName}Key.pem --type ${KeyType} | ${IpsecProgram} pki --issue --lifetime ${LeftLifeTime} --cacert ipsec.d/cacerts/${CAName}Cert.pem --cakey ipsec.d/private/${CAName}Key.pem --dn "${LeftSubjectName}" ${LeftSanFlagString} --outform pem > ipsec.d/certs/${LeftName}Cert.pem

  ${IpsecProgram} pki --print --in ipsec.d/certs/${LeftName}Cert.pem
fi

if [ ${GenRight} == "1" ]; then
  ${IpsecProgram} pki --gen --type ${KeyType} --size ${KeySize} --outform pem > ipsec.d/private/${RightName}Key.pem
  chmod 600 ipsec.d/private/${RightName}Key.pem

  ${IpsecProgram} pki --pub --in ipsec.d/private/${RightName}Key.pem --type ${KeyType} | ${IpsecProgram} pki --issue --lifetime ${RightLifeTime} --cacert ipsec.d/cacerts/${CAName}Cert.pem --cakey ipsec.d/private/${CAName}Key.pem --dn "${RightSubjectName}" ${RightSanFlagString} --outform pem > ipsec.d/certs/${RightName}Cert.pem
  
  ${IpsecProgram} pki --print --in ipsec.d/certs/${RightName}Cert.pem
fi

if [ ${GenP12} == "1" ]; then
  openssl pkcs12 -export  -inkey ipsec.d/private/${RightName}Key.pem -in ipsec.d/certs/${RightName}Cert.pem -name "${RightName}'s VPN Certificate"  -certfile ipsec.d/cacerts/${CAName}Cert.pem -caname ${CAName} -out ~/${RightName}.p12
fi

if [ ${GenTar} == "1" ]; then
  tar zcvf ~/${RightName}_Linux.tar.gz ipsec.d/private/${RightName}Key.pem ipsec.d/certs/${RightName}Cert.pem ipsec.d/cacerts/${CAName}Cert.pem
fi
