#!/usr/bin/env bash

# Configuration

. ./config-demo-openshift-fuse-msa.sh || { echo "FAILED: Could not verify configuration" && exit 1; }

# Additional Configuration
# none 

echo -n "Verifying configuration ready..."
: ${DEMO_INTERACTIVE?}
: ${DEMO_INTERACTIVE_PROMPT?}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS?}
: ${APPLICATION_NAME}
: ${OPENSHIFT_USER_REFERENCE?}
: ${OPENSHIFT_APPS?}
echo "OK"
echo "Setup Fuse MSA Demo Configuration_____________________________________"
echo "	APPLICATION_NAME                     = ${APPLICATION_NAME}"
echo "	OPENSHIFT_USER_REFERENCE             = ${OPENSHIFT_USER_REFERENCE}"
echo "	OPENSHIFT_APPLICATION_NAME           = ${OPENSHIFT_APPLICATION_NAME}"
echo "	OPENSHIFT_APPS                       = ${OPENSHIFT_APPS}"
echo "	OPENSHIFT_PROJECT_FUSE_MSA           = ${OPENSHIFT_PROJECT_FUSE_MSA}"
echo "____________________________________________________________"

echo "Setup Fuse MSA demo"
echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_FUSE_MSA} || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

echo "	--> checking your account for sufficient resources"
[ "`oc get quota --template='{{range .items}}{{if (eq .kind "ResourceQuota")}}{{.spec.hard.services}}{{end}}{{end}}'`" -ge 10 ] || { echo "FAILED: your account does not have enough service quota to succeed -- contact your system adminstrator to request additional quota" && exit 1; }

[ "x${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS}" != "xfalse" ] || { echo "	--> Verify the openshift cluster is working normally" && oc status -v >/dev/null || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; } ; }

echo "	--> create configuration resources"
# source from  https://github.com/RHsyseng/FIS2-MSA
mkdir -p yaml-templates
APPLICATION_RESOURCES=(yaml-templates/logging-deployer.yaml yaml-templates/billing-template.yaml yaml-templates/gateway-template.yaml yaml-templates/messaging-template.yaml yaml-templates/presentation-template.yaml yaml-templates/product-template.yaml yaml-templates/sales-template.yaml yaml-templates/warehouse-template.yaml yaml-templates/logging-accounts.sh)
for APPLICATION_RESOURCE in ${APPLICATION_RESOURCES[*]} ; do
	{ [ -f ${APPLICATION_RESOURCE} ] && echo "Resource ${APPLICATION_RESOURCE} is already available" ; } || { echo "	--> Attempting to download resource ${APPLICATION_RESOURCE}" && curl -sSKL -o ${APPLICATION_RESOURCE} https://raw.githubusercontent.com/RHsyseng/FIS2-MSA/master/${APPLICATION_RESOURCE} ; } || { echo "FAILED: could not download resource ${APPLICATION_RESOURCE}" && exit 1; }
done
# only necessary if logging needs to be set up; if already on a cluster with logging available this is unnecessary
#chmod +x yaml-templates/logging-accounts.sh

echo "	--> Create the product database"
oc get dc/product-db || oc new-app --name=product-db -l parent-app=${APPLICATION_NAME} -l part=product-db -e MYSQL_USER=product -e MYSQL_PASSWORD=password -e MYSQL_DATABASE=product -e MYSQL_ROOT_PASSWORD=passwd mysql || { echo "FAILED: Could not find or create the app=${APPLICATION_NAME},part=product-db " && exit 1; } ;
echo "	--> Create the sales database"
oc get dc/sales-db || oc new-app --name=sales-db -l parent-app=${APPLICATION_NAME} -l part=sales-db -e MYSQL_USER=sales -e MYSQL_PASSWORD=password -e MYSQL_DATABASE=sales -e MYSQL_ROOT_PASSWORD=passwd mysql --name=sales-db  || { echo "FAILED: Could not find or create the app=${APPLICATION_NAME},part=sales-db" && exit 1; } ;

echo "	--> Waiting for the sales database application component to start....press any key to proceed"
while ! oc get pods | grep product-db | grep Running && ! oc get pods | grep sales-db | grep Running ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""

oc get template/messaging-template || oc process -l parent-app=${APPLICATION_NAME}  -f yaml-templates/messaging-template.yaml -p AMQ_USER=mquser -p AMQ_PASSWORD=password | oc create -f -
echo "	--> Waiting for the message services to start....press any key to proceed"
while ! oc get svc/broker-amq-amqp && ! oc get svc/broker-amq-stomp && ! oc get svc/broker-amq-mqtt ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""
oc delete svc/broker-amq-amqp
oc delete svc/broker-amq-stomp
oc delete svc/broker-amq-mqtt

oc get template/billing-template || oc process -f yaml-templates/billing-template.yaml | jq '(.items[] | .metadata.labels) += {"parent-app": "'"${APPLICATION_NAME}"'"}' | jq '(.items[] | .metadata.labels.part ) = "billing-service"' | oc create -f -
if oc get bc/billing-service ; then 
	oc cancel-build bc/billing-service || { echo "WARNING: could not cancel build for billing service" ; }
	oc patch bc/billing-service -p '{ "spec" : {  "resources" : { "requests" : { "cpu" : "900m" , "memory" : "1000Mi" } , "limits" : { "cpu" : "1000m" , "memory" : "1500Mi" } } } }' || { echo "FAILED: could not patch build configuration to ensure sufficient build resources" && exit 1 ; }
	oc start-build bc/billing-service || { echo "WARNING: could not restart build for billing service" ; }
fi

oc get template/warehouse-template || oc process -f yaml-templates/warehouse-template.yaml | jq '(.items[] | .metadata.labels) += {"parent-app": "'"${APPLICATION_NAME}"'"}' | jq '(.items[] | .metadata.labels.part ) = "warehouse-service"' | oc create -f -
if oc get bc/warehouse-service ; then 
	oc cancel-build bc/warehouse-service || { echo "WARNING: could not cancel build for gateway service" ; }
	oc patch bc/warehouse-service -p '{ "spec" : {  "resources" : { "requests" : { "cpu" : "900m" , "memory" : "1000Mi" } , "limits" : { "cpu" : "1000m" , "memory" : "1500Mi" } } } }' || { echo "FAILED: could not patch build configuration to ensure sufficient build resources" && exit 1 ; }
	oc start-build bc/warehouse-service || { echo "WARNING: could not restart build for gateway service" ; }
fi

oc get template/gateway-template || oc process -f yaml-templates/gateway-template.yaml | jq '(.items[] | .metadata.labels) += {"parent-app": "'"${APPLICATION_NAME}"'"}' | jq '(.items[] | .metadata.labels.part ) = "gateway-service"' | oc create -f -
if oc get bc/gateway-service ; then 
	oc cancel-build bc/gateway-service || { echo "WARNING: could not cancel build for gateway service" ; }
	oc patch bc/gateway-service -p '{ "spec" : {  "resources" : { "requests" : { "cpu" : "900m" , "memory" : "1000Mi" } , "limits" : { "cpu" : "1000m" , "memory" : "1500Mi" } } } }' || { echo "FAILED: could not patch build configuration to ensure sufficient build resources" && exit 1 ; }
	oc start-build bc/gateway-service || { echo "WARNING: could not restart build for gateway service" ; }
fi

oc get template/product-template || oc process -f yaml-templates/product-template.yaml | jq '(.items[] | .metadata.labels) += {"parent-app": "'"${APPLICATION_NAME}"'"}' | jq '(.items[] | .metadata.labels.part ) = "product-service"' | oc create -f -
oc get template/sales-template || oc process -f yaml-templates/sales-template.yaml | jq '(.items[] | .metadata.labels) += {"parent-app": "'"${APPLICATION_NAME}"'"}' | jq '(.items[] | .metadata.labels.part ) = "sales-service"' | oc create -f -
oc get template/presentation-template || oc process -f yaml-templates/presentation-template.yaml -p ROUTE_URL=presentation.${OPENSHIFT_APPS} | jq '(.items[] | .metadata.labels) += {"parent-app": "'"${APPLICATION_NAME}"'"}' | jq '(.items[] | .metadata.labels.part ) = "presentation-service"' | oc create -f -
# oc scale dc product-service --replicas=3

echo "	--> populating the application database"
curl -sSKL http://presentation.${OPENSHIFT_APPS}/demo.jsp

echo "	--> application logs are avaialable at logging.${OPENSHIFT_DOMAIN}/app/kibana"

echo "Done."
