#!/bin/bash

set -eu
set -o pipefail

export OP_ROOT=https://raw.githubusercontent.com/teiid/teiid-operator/master/deploy
export REGISTRY=registry.redhat.io

create_secret_if_not_present() {
  if $(check_resource secret dv-pull-secret) ; then
    echo "pull secret 'dv-pull-secret' present, skipping creation ..."
  else
    echo "pull secret 'dv-pull-secret' is missing, creating ..."
    echo "enter username for ${REGISTRY} and press [ENTER]: "
    read username
    echo "enter password for ${REGISTRY} and press [ENTER]: "
    read -s password
    local result=$(oc create secret docker-registry dv-pull-secret --docker-server=${REGISTRY} --docker-username=$username --docker-password=$password)
    check_error $result
  fi
}

# Check if a resource exist in OCP
check_resource() {
  local kind=$1
  local name=$2
  oc get $kind $name -o name >/dev/null 2>&1
  if [ $? != 0 ]; then
    echo "false"
  else
    echo "true"
  fi
}

# create a secret for pulling the image
create_secret_if_not_present
oc secrets link builder dv-pull-secret
oc secrets link builder dv-pull-secret --for=pull

oc create -f $OP_ROOT/crds/virtualdatabase.crd.yaml
oc create -f $OP_ROOT/service_account.yaml
oc create -f $OP_ROOT/role.yaml
oc create -f $OP_ROOT/role_binding.yaml
oc create -f $OP_ROOT/operator.yaml

