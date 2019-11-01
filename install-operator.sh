#!/bin/sh

export OP_ROOT=https://raw.githubusercontent.com/teiid/teiid-operator/master/deploy
export REGISTRY=quay.io
export RESOURCE=teiid-operator

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

# check error
check_error() {
    local msg="$*"
    if [ "${msg//ERROR/}" != "${msg}" ]; then
        if [ -n "${ERROR_FILE:-}" ] && [ -f "$ERROR_FILE" ] && ! grep "$msg" $ERROR_FILE ; then
            local tmp=$(mktemp /tmp/error-XXXX)
            echo ${msg} >> $tmp
            if [ $(wc -c <$ERROR_FILE) -ne 0 ]; then
              echo >> $tmp
              echo "===============================================================" >> $tmp
              echo >> $tmp
              cat $ERROR_FILE >> $tmp
            fi
            mv $tmp $ERROR_FILE
        fi
        exit 0
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

if $(check_resource crd virtualdatabases.teiid.io) ; then 
  echo "CRD Already exists, skipping.."
else
  oc create -f $OP_ROOT/crds/virtualdatabase.crd.yaml 
fi

if $(check_resource ServiceAcccount ${RESOURCE}) ; then 
  echo "Service Account already exists, skipping.."
else
  echo "creating sa"
  oc create -f $OP_ROOT/service_account.yaml
fi

if $(check_resource role ${RESOURCE}) ; then 
  echo "Role already exists, skipping.."
else
  oc create -f $OP_ROOT/role.yaml
fi

if $(check_resource rolebinding ${RESOURCE}) ; then 
  echo "RoleBinding already exists, skipping.."
else
  oc create -f $OP_ROOT/role_binding.yaml
fi

if $(check_resource deployment ${RESOURCE}) ; then 
  echo "Operator already exists, skipping.."
else
  oc create -f $OP_ROOT/operator.yaml
fi