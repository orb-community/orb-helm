branch = main # defaults
all:
	echo "package, upload, index. deploy will do all."

deploy: package upload index
	echo "done"

package:
	git checkout $(branch)
	rm -rf .deploy/*
	helm package charts/orb -u --destination .deploy

upload:
	git checkout $(branch)
	cr upload --config cr-config.yaml --token $(ghtoken)

index:
	git checkout gh-pages
	cr index -i ./index.yaml --config cr-config.yaml --token $(ghtoken) -c https://orb-community.github.io/orb-helm/
	git commit -a -m "release"
	git push
	git checkout $(branch)

prepare-helm:
	cd charts/orb && helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
	cd charts/orb && ls -lha && rm -rf Chart.lock && helm dependency build
	cd ../..

kind-create-all: kind-create-cluster kind-load-images kind-install-orb

kind-upgrade-all: kind-load-images kind-upgrade-orb

kind-create-cluster:
	kind create cluster --image kindest/node:v1.23.0 --config=./kind/config.yaml

kind-delete-cluster:
	kind delete cluster

kind-load-images:
	kind load docker-image ns1labs/orb-fleet:develop
	kind load docker-image ns1labs/orb-policies:develop
	kind load docker-image ns1labs/orb-sinks:develop
	kind load docker-image ns1labs/orb-sinker:develop
	kind load docker-image ns1labs/orb-migrate:develop
	kind load docker-image ns1labs/orb-ui:develop

kind-install-orb:
	kubectl create namespace orb
	kubectl create secret generic orb-auth-service --from-literal=jwtSecret=MY_SECRET -n orb
	kubectl create secret generic orb-user-service --from-literal=adminEmail=admin@kind.com --from-literal=adminPassword=pass123456 -n orb
	kubectl create secret generic orb-sinks-encryption-key --from-literal=key=MY_SINKS_SECRET -n orb
	helm install \
		--set fleet.image.pullPolicy=Never \
		--set policies.image.pullPolicy=Never \
		--set sinks.image.pullPolicy=Never \
		--set sinker.image.pullPolicy=Never \
		--set ui.image.pullPolicy=Never \
		--set defaults.replicaCount=1 \
		--set nginx_internal.kindDeploy=true \
		--set keto.keto.config.dsn=postgres://postgres:orb@kind-orb-postgresql-keto:5432/keto \
		--set keto.keto.autoMigrate=true \
		--set ingress.hostname=kubernetes.docker.internal \
		-n orb \
		kind-orb ./charts/orb
	kubectl apply -f ./kind/nginx.yaml

kind-upgrade-orb:
	helm upgrade \
		--set fleet.image.pullPolicy=Never \
		--set policies.image.pullPolicy=Never \
		--set sinks.image.pullPolicy=Never \
		--set sinker.image.pullPolicy=Never \
		--set ui.image.pullPolicy=Never \
		--set defaults.replicaCount=1 \
		--set nginx_internal.kindDeploy=true \
		--set keto.keto.config.dsn=postgres://postgres:orb@kind-orb-postgresql-keto:5432/keto \
		--set keto.keto.autoMigrate=true \
		--set ingress.hostname=kubernetes.docker.internal \
		-n orb \
		kind-orb ./charts/orb

kind-delete-orb:
	kubectl delete -f ./kind/nginx.yaml
	helm delete -n orb kind-orb
	kubectl delete secret generic orb-user-service -n orb
	kubectl delete secret generic orb-auth-service -n orb
	kubectl delete namespace orb
