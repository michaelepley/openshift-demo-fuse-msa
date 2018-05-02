#!/usr/bin/env bash
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

echo "Cleaning up Fuse MSA demo application"
echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd config
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT_FUSE_MSA} || { echo "FAILED: Could not login" && exit 1; }
popd

[ "x${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS}" != "xfalse" ] || { echo "	--> Verify the openshift cluster is working normally" && oc status -v >/dev/null || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; } ; }

echo "	--> delete all openshift resources"
oc delete all -l parent-app=${APPLICATION_NAME}
# note: the secret is not labeled _or_ captured by the delete all above and must be expressly deleted
oc delete secret mysql
echo "	--> delete project"
#oc delete project ${OPENSHIFT_PROJECT_FUSE_MSA}
echo "	--> delete all local artifacts"
rm -rf yaml-templates || echo "WARNING: could not remove yaml-templates resource"
echo "Done"
