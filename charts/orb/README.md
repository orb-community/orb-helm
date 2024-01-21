# Orb Helm Chart

Helm Chart for the Orb Observability Platform

## Prerequisites

- Helm v3

## Configuration

## Instructions

This guide assumes installation into name space `orb`. It requires a HOSTNAME you have DNS control over. It uses Let's
Encrypt for TLS certification management.

* cd to working directory `charts/orb`
* Add helm repos for dependencies

```
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm dependency update
```

* Create `orb` and `otelcollectors` namespace

```
kubectl create namespace orb
kubectl create namespace otelcollectors
```

* Create JWT signing key secret

```
kubectl create secret generic orb-auth-service --from-literal=jwtSecret=MY_SECRET -n orb
```

* Create sinks encryption password
```
kubectl create secret generic orb-sinks-encryption-key --from-literal=key=mainflux-orb -n orb
```

* Create keto dsn secret
```
kubectl create secret generic orb-keto-dsn --from-literal=dsn='postgres://postgres:orb@orb-postgresql-keto:5432/keto' -n orb
```

* Create admin user secrets

```
kubectl create secret generic orb-user-service --from-literal=adminEmail=user@example.com --from-literal=adminPassword=12345678 -n orb
```

* Install orb. Replace `orb` with your helm release name, also set your HOSTNAME as a valid domain to expose service properly, remember that should generate a certificate for that.
Check the [optional variables](#optional-variables-to-set) for more options. 

```
helm install --set ingress.hostname=HOSTNAME -n orb orb .
```

On <b>AWS EKS</b>: 
Once that you can update your ingress controller (AWS LoadBalancer) using helm, a good solution could be you open the MQTT port on the cluster loadbalancer and redirect it to <b>orb-nginx-internal</b> pod as below:
* Deploy [ingres-nginx helm](https://kubernetes.github.io/ingress-nginx/deploy/#using-helm) (to default namespace) with
  tcp config map configured from helm for 8883 (MQTTS). Note you need to reference both namespace and helm release name
  here!

```
helm install --set tcp.8883=orb/orb-nginx-internal:8883 ingress-nginx ingress-nginx/ingress-nginx
```

On <b>On-Premise kubernetes cluster</b>: 
The best approach is use nginx-internal as service type LoadBalancer on your values.yaml to expose your MQTT port externally

```
helm install --set tcp.8883=orb/orb-nginx-internal:8883 ingress-nginx ingress-nginx/ingress-nginx
```

* Wait for an external IP to be available

```
kubectl --namespace default get services -o wide -w ingress-nginx-controller
```

* Choose a HOSTNAME, then point an A record for this hostname to the external IP
* Deploy [cert manager helm](https://cert-manager.io/docs/installation/helm/)
  to [secure nginx ingress](https://cert-manager.io/docs/tutorials/acme/ingress/)

```
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.5.3 --set installCRDs=true
```

* Create Issuer CRDs (in the `orb` namespace!)
  * `cp issuers/production-issuer-tpt.yaml issuers/production-issuer.yaml`
  * edit `issuers/production-issuer.yaml` and change `spec.acme.email` to a real email address
  * `kubectl create -f issuers/production-issuer.yaml -n orb`

To restart entire deployment:

```
kubectl rollout restart deployment -n orb
```

## Known-bug:
Sometimes on the first run, postgres can have a problem to seed your password. To fix this, you have to manually remove the persistent volume claim (PVC) which will free up the database storage.

```
kubectl delete pvc data-my-db-postgresql-0
```
(Or whatever the PVC associated with your initial Helm install was named.)
After remove the pvc, you need to restart the respective pod.

### Optional variables to set
- **SMTP**

   Set the following variables to enable SMTP support for password recovery:
  - `smtp.host`: SMTP server hostname to send e-mails to.
  - `smtp.port`: SMTP server port, defaults to `25`.
  - `smtp.fromName`: E-mail sender display name. Defaults to `Orb`.
  - `smtp.fromAddress`: E-mail address of the sender.
  - `smtp.usernmame`: username used when authenticating to the SMTP server used for sending e-emails. 
  - `smtp.password`: password used when authenticating to the SMTP server used for sending e-emails.
