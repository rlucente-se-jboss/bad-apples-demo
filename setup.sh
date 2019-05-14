#!/usr/bin/env bash

. $(dirname $0)/demo.conf

PUSHD $WORKDIR

oc logout
oc login -u ${DEV_USER} -p ${DEV_PASS} https://${MASTER}:8443

oc delete project ${PROJECT}
oc new-project ${PROJECT}

oc create -f https://radanalytics.io/resources.yaml

rm -f rad-validate
curl -o rad-validate https://radanalytics.io/assets/tools/rad-validate
chmod +x rad-validate
./rad-validate

oc new-app oshinko-webui
oc new-app postgresql-persistent \
    --name postgresql \
    -e POSTGRESQL_USER=username \
    -e POSTGRESQL_PASSWORD=password \
    -e POSTGRESQL_DATABASE=finance

oc create -f https://raw.githubusercontent.com/radanalyticsio/bad-apples/master/loader/data-loader.yaml

oc new-app --template=data-loader --name=loader

oc new-app python~https://github.com/radanalyticsio/bad-apples \
    --context-dir=watcher \
    -e DBHOST=postgresql \
    -e DBNAME=finance \
    -e DBUSERNAME=username \
    -e DBPASSWORD=password \
    --name=watcher

oc expose svc/watcher

oc create -f https://raw.githubusercontent.com/radanalyticsio/bad-apples/master/filter/filter.yaml

oc get pods

# deploy che
oc process -f https://raw.githubusercontent.com/minishift/minishift/master/addons/che/templates/che-workspace-service-account.yaml \
    --param SERVICE_ACCOUNT_NAMESPACE=${PROJECT} --param=SERVICE_ACCOUNT_NAME=che-workspace | oc create -f -
 
oc process -f https://raw.githubusercontent.com/minishift/minishift/master/addons/che/templates/che-server-template.yaml \
    --param ROUTING_SUFFIX=${APPS} \
    --param CHE_MULTIUSER=false \
    --param CHE_INFRA_OPENSHIFT_PROJECT=${PROJECT} \
    --param CHE_INFRA_KUBERNETES_SERVICE__ACCOUNT__NAME=che-workspace | oc create -f -
 
oc set resources dc/che --limits=cpu=1,memory=2Gi --requests=cpu=200m,memory=512Mi

echo
echo "Fork GitHub repo https://github.com/radanalyticsio/bad-apples"
echo "In Eclipse Che ... "
echo "  Project Import GITHUB URL:  https://<your github username>:'<your github password'@github.com/<your github username>/bad-apples.git"
echo "  Then open the files ...
echo "    bad-apples/filter/src/main/resources/io/radanalytics/limitfilter/fraud.drl"
echo "    bad-apples/filter/src/main/java/io/radanalytics/limitfilter/LimitFilter.java"
echo

POPD

