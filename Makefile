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

