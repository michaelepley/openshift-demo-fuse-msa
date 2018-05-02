#!/usr/bin/env bash

# Note: requires bash 4.2 or later

# assume the demo is interactive
: ${DEMO_INTERACTIVE:=true}
: ${DEMO_INTERACTIVE_PROMPT_TIMEOUT_SECONDS:=30}

DEMO_TARGET_OPENSHIFT_INSTANCES=(local rhsademo fortnebula itpaas nsabine-vrtx)
# Target RHSADEMO
DEMO_TARGET_OPENSHIFT_INSTANCE=${DEMO_TARGET_OPENSHIFT_INSTANCES[1]}

APPLICATION_NAME=fuse-msa

# assume we don't need to expressly verify the clusters operational status
: ${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS:=false}

# Configuration
pushd config >/dev/null 2>&1
. ./config.sh || { echo "FAILED: Could not configure generic demo environment" && exit 1 ; }
# we will be using github for this demo, so load these configuration resources 
. ./config-resources-github.sh || { echo "FAILED: Could not configure github demo resources" && exit 1 ; }
popd >/dev/null 2>&1

[[ -v CONFIGURATION_DEMO_OPENSHIFT_FUSE_MSA_COMPLETED ]] && echo "Using openshift simple demo configuration" && { return || exit ; }
: ${CONFIGURATION_DEMO_OPENSHIFT_FUSE_MSA_DISPLAY:=$CONFIGURATION_DISPLAY}
# uncomment to force these scripts to display coniguration information
CONFIGURATION_DEMO_OPENSHIFT_FUSE_MSA_DISPLAY=true

# Demo specific configuration items
# modify the user, or copy to new reference, then modufy
#OPENSHIFT_USER_PROJECT_REF="OPENSHIFT_USER_RHSADEMO_MEPLEY[3]" && eval "${OPENSHIFT_USER_PROJECT_REF}=mepley-myphp"
OPENSHIFT_USER_RHSADEMO_MEPLEY_DEMO_FUSE_MSA=(${OPENSHIFT_USER_RHSADEMO_MEPLEY[@]})
OPENSHIFT_USER_RHSADEMO_MEPLEY_DEMO_FUSE_MSA[3]=mepley-fuse-msa
: ${OPENSHIFT_PROJECT_FUSE_MSA_DEFAULT:=${OPENSHIFT_USER_RHSADEMO_MEPLEY_DEMO_FUSE_MSA[0]}-fuse-msa}
OPENSHIFT_PROJECT_FUSE_MSA=${OPENSHIFT_PROJECT_FUSE_MSA_DEFAULT}

#OPENSHIFT_USER_REFERENCE_PRIMARY_DEFAULT
# Set the base configuration variables for the openshift-demo-fusa-msa
: ${OPENSHIFT_DOMAIN:=$OPENSHIFT_DOMAIN_DEFAULT}
: ${OPENSHIFT_MASTER:=$OPENSHIFT_MASTER_PRIMARY_DEFAULT}
: ${OPENSHIFT_APPS:=$OPENSHIFT_APPS_PRIMARY_DEFAULT}
: ${OPENSHIFT_PROXY_AUTH:=$OPENSHIFT_PROXY_AUTH_PRIMARY_DEFAULT}
OPENSHIFT_USER_REFERENCE=${OPENSHIFT_USER_REFERENCE_PRIMARY_DEFAULT}
: ${OPENSHIFT_USER:=$OPENSHIFT_USER_PRIMARY_DEFAULT}
: ${OPENSHIFT_USER_PASSWORD:=$OPENSHIFT_USER_PRIMARY_PASSWORD_DEFAULT}
: ${OPENSHIFT_AUTH_METHOD:=$OPENSHIFT_AUTH_METHOD_PRIMARY_DEFAULT}
OPENSHIFT_PROJECT=${OPENSHIFT_PROJECT_FUSE_MSA_DEFAULT}
: ${OPENSHIFT_OUTPUT_FORMAT:=$OPENSHIFT_OUTPUT_FORMAT_DEFAULT}

if [ "$CONFIGURATION_DEMO_OPENSHIFT_FUSE_MSA_DISPLAY" != "false" ]; then
	echo "Demo Openshift Simple Configuration_________________________"
	echo "	APPLICATION_NAME                        = ${APPLICATION_NAME}"
	echo "	OPENSHIFT_USER_REFERENCE_PRIMARY_DEFAULT = ${OPENSHIFT_USER_REFERENCE_PRIMARY_DEFAULT}"
	echo "	OPENSHIFT_USER_RHSADEMO_MEPLEY_DEMO_FUSE_MSA = ${OPENSHIFT_USER_RHSADEMO_MEPLEY_DEMO_FUSE_MSA[@]}"
	echo "	OPENSHIFT_PROJECT_FUSE_MSA_DEFAULT      =${OPENSHIFT_PROJECT_FUSE_MSA_DEFAULT}"
	echo "	OPENSHIFT_PROJECT_FUSE_MSA              = ${OPENSHIFT_PROJECT_FUSE_MSA}"
	echo "	OPENSHIFT_DOMAIN                        = ${OPENSHIFT_DOMAIN}"
	echo "	OPENSHIFT_MASTER                        = ${OPENSHIFT_MASTER_PRIMARY_DEFAULT}"
	echo "	OPENSHIFT_APPS                          = ${OPENSHIFT_APPS}"
	echo "	OPENSHIFT_PROXY_AUTH                    = ${OPENSHIFT_PROXY_AUTH}"
	echo "	OPENSHIFT_USER_REFERENCE                = ${OPENSHIFT_USER_REFERENCE}"
	echo "	OPENSHIFT_USER                          = ${OPENSHIFT_USER}"
	echo "	OPENSHIFT_USER_PASSWORD                 = `echo ${OPENSHIFT_USER_PASSWORD} | md5sum` (obfuscated)"
	echo "	OPENSHIFT_AUTH_METHOD                   = ${OPENSHIFT_AUTH_METHOD}"
	echo "	OPENSHIFT_PROJECT                       = ${OPENSHIFT_PROJECT}"
	echo "	OPENSHIFT_APPLICATION_NAME              = ${OPENSHIFT_APPLICATION_NAME}"
	echo "	OPENSHIFT_OUTPUT_FORMAT                 = ${OPENSHIFT_OUTPUT_FORMAT}"
	echo "____________________________________________________________"
fi

CONFIGURATION_DEMO_OPENSHIFT_FUSE_MSA_COMPLETED=true
