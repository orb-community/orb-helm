all:
	echo "package, upload, index. deploy will do all."

deploy: package upload index
	echo "done"

package:
	git checkout main
	rm .deploy/*
	helm package charts/orb -u --destination .deploy

upload:
	git checkout main
	cr upload --config cr-config.yaml

index:
	git checkout gh-pages
	cr index -i ./index.yaml --config cr-config.yaml -c https://ns1labs.github.io/orb-helm/
	git commit -a -m "release"
	git push
	git checkout main

prepare-helm:
	cd charts/orb
	helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
	helm dependency build
	cd ../..

kind-create-all: kind-create-cluster kind-install-orb

kind-create-cluster:
	kind create cluster --image kindest/node:v1.23.0 --config=./kind/config.yaml

kind-delete-cluster:
	kind delete cluster

kind-install-orb:
	kubectl create namespace orb
	kubectl create secret generic orb-auth-service --from-literal=jwtSecret=MY_SECRET -n orb
	kubectl create secret generic orb-user-service --from-literal=adminEmail=admin@kind.com --from-literal=adminPassword=pass123456 -n orb
	helm install --set defaults.replicaCount=1 --set nginx_internal.kindDeploy=true --set ingress.hostname=kubernetes.docker.internal -n orb kind-orb ./charts/orb
	kubectl apply -f ./kind/nginx.yaml

kind-delete-orb:
	kubectl delete -f ./kind/nginx.yaml
	helm delete -n orb kind-orb
	kubectl delete secret generic orb-user-service -n orb
	kubectl delete secret generic orb-auth-service -n orb
	kubectl delete namespace orb
