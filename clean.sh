#!/usr/bin/env bash

. $(dirname $0)/demo.conf

PUSHD $WORKDIR

oc logout
oc login -u ${ADMIN_USER} -p ${ADMIN_PASS}  https://${MASTER}:8443
 
oc project ${PROJECT}
oc delete all --all -n ${PROJECT}
oc delete project ${PROJECT}
 
rm -f rad-validate

for i in $(oc get pv | grep -v Available | grep '^vol' | awk '{print $1}')
do
    oc patch pv/$i --type json -p $'- op: remove\n  path: /spec/claimRef'
done

echo "Provide root password for $MASTER if prompted"
ssh root@${MASTER} 'cd /mnt/data && find . -type d | grep '^./vol[0-9]*/' | cut -d/ -f1-3 | sort -u | xargs rm -fr'

POPD

