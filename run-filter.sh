#!/usr/bin/env bash

oc new-app --template=filter \
  -p IMAGE=$(oc get is filter --template={{.status.dockerImageRepository}}) \
  -p OSHINKO_CLUSTER_NAME=sparky

