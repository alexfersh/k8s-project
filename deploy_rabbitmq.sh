#!/bin/bash

RABBITMQ_REGISTRY=bitnami\/rabbitmq
HELM_REPO=https\:\/\/charts.bitnami.com\/bitnami
echo "RabbitMQ Registry:" $RABBITMQ_REGISTRY
echo "Bitnami Helm Repository:" $HELM_REPO

helm repo add bitnami $HELM_REPO
helm repo update
namespace=$(cat ./helm/values.yaml | grep -w namespace: | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f2)
echo "Namespace:" $namespace
releasename=$(cat ./helm/values.yaml | grep -w releasename: | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f2)
echo "Helm release name:" $releasename

check_namespace=$(kubectl get namespace | grep -w $namespace | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f1)
echo "Namespace to check:" $check_namespace
if [[ -z $check_namespace ]]; then
        echo "No appropriate namespace for the project was found. Creating namespace $namespace as per the project settings..."
	kubectl create namespace $namespace
fi

check_release=$(helm --namespace=$namespace list | grep -w $releasename | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f1)
echo "Helm release to check:" $check_release
if [[ -z $check_release ]]; then

        echo "RabbitMQ Helm chart is not installed. Installing it..."

	helm upgrade $releasename $RABBITMQ_REGISTRY -f rabbitmq-values.yaml --install --force --namespace=$namespace --create-namespace

	cluster_ip=`kubectl --namespace $namespace get svc | grep -w $releasename | grep -v headless | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f3`
	podname=`kubectl --namespace $namespace get pods | grep -w rabbitmq-0 | cut -d ' ' -f1`
	rabbitmq_username=`kubectl --namespace $namespace describe pods $podname | grep -w RABBITMQ_USERNAME: | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f3`
	rabbitmq_secret=`kubectl --namespace $namespace describe pods $podname | grep -w RABBITMQ_PASSWORD: | tr '\t\n' ' ' | tr -s ' ' | tr -d "<'>" | cut -d ':' -f2 | cut -d ' ' -f9`
	rabbitmq_password=`kubectl --namespace $namespace get secret $rabbitmq_secret -o jsonpath="{.data.rabbitmq-password}" | base64 -d`

	sed -i "s/rabbitmq/$cluster_ip/" ./helm/templates/producer-deployment.yaml
	sed -i "s/rabbitmq/$cluster_ip/" ./helm/templates/consumer-deployment.yaml
	sed -i "s/('guest', 'guest')/('$rabbitmq_username', '$rabbitmq_password')/" ./consumer/consumer.py
	sed -i "s/('guest', 'guest')/('$rabbitmq_username', '$rabbitmq_password')/" ./producer/producer.py

else
        echo "RabbitMQ installation was found. Upgrading release..."

	podname=`kubectl --namespace $namespace get pods | grep -w rabbitmq-0 | cut -d ' ' -f1`
	rabbitmq_secret=`kubectl --namespace $namespace describe pods $podname | grep -w RABBITMQ_PASSWORD: | tr '\t\n' ' ' | tr -s ' ' | tr -d "<'>" | cut -d ':' -f2 | cut -d ' ' -f9`
	RABBITMQ_PASSWORD=$(kubectl --namespace $namespace get secret $rabbitmq_secret -o jsonpath="{.data.rabbitmq-password}" | base64 -d)
	RABBITMQ_ERLANG_COOKIE=$(kubectl --namespace $namespace get secret $rabbitmq_secret -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 -d)

	helm upgrade $releasename $RABBITMQ_REGISTRY -f rabbitmq-values.yaml --install --force --namespace=$namespace --create-namespace --set auth.password=$RABBITMQ_PASSWORD --set auth.erlangCookie=$RABBITMQ_ERLANG_COOKIE

	cluster_ip=`kubectl --namespace $namespace get svc | grep -w $releasename | grep -v headless | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f3`
	podname=`kubectl --namespace $namespace get pods | grep -w rabbitmq-0 | cut -d ' ' -f1`
	rabbitmq_username=`kubectl --namespace $namespace describe pods $podname | grep -w RABBITMQ_USERNAME: | tr '\t\n' ' ' | tr -s ' ' | cut -d ' ' -f3`
	rabbitmq_secret=`kubectl --namespace $namespace describe pods $podname | grep -w RABBITMQ_PASSWORD: | tr '\t\n' ' ' | tr -s ' ' | tr -d "<'>" | cut -d ':' -f2 | cut -d ' ' -f9`
	rabbitmq_password=`kubectl --namespace $namespace get secret $rabbitmq_secret -o jsonpath="{.data.rabbitmq-password}" | base64 -d`

	sed -i "s/rabbitmq/$cluster_ip/" ./helm/templates/producer-deployment.yaml
	sed -i "s/rabbitmq/$cluster_ip/" ./helm/templates/consumer-deployment.yaml
	sed -i "s/('guest', 'guest')/('$rabbitmq_username', '$rabbitmq_password')/" ./consumer/consumer.py
	sed -i "s/('guest', 'guest')/('$rabbitmq_username', '$rabbitmq_password')/" ./producer/producer.py

fi
