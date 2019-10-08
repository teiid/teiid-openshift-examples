#!/bin/sh

export OP_ROOT=https://raw.githubusercontent.com/teiid/teiid-operator/7.5-0.0.x/deploy
oc create -f $OP_ROOT/crds/virtualdatabase.crd.yaml
oc create -f $OP_ROOT/service_account.yaml
oc create -f $OP_ROOT/role.yaml
oc create -f $OP_ROOT/role_binding.yaml
oc create -f $OP_ROOT/operator.yaml
