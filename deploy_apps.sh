#!/bin/bash

export namespace=`cat ./helm/values.yaml | grep -w namespace: | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f2`
export releasename=`cat ./helm/values.yaml | grep -w releasename: | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f2`
helm upgrade $releasename-cons-prod ./helm --install --force --namespace=$namespace --create-namespace
