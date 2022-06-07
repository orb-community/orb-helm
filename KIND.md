# Kind local cluster

Kind is a tool for running local k8s clusters using docker container as nodes.

## 🚧 Install Kind

if you have `go 1.17` installed
```shell
go install sigs.k8s.io/kind@v0.14.0
```

macOS
```shell
brew install kind
```

> 🚨 **Windows WSL users**: WSL is also supported, but for some reason the Orb stack mess up the WSL internal DNS.
> You can fix that by editing your `/etc/wsl.conf` and adding the following:
> ```shell
> [network]
> generateResolvConf = false
> ```
> Then remove the symbolic link from `/etc/resolv.conf`:
> ```shell
> sudo unlink /etc/resolv.conf
> ```
> Create a new `/etc/resolv.conf` file and add the following:
> ```shell
> nameserver 8.8.8.8
> ```
> save the file and you are done.

## 🚀  Deploy Orb on Kind

Use the following command to create the cluster and deploy **Orb**

```shell
make kind-create-all
```

Access the **Orb UI** by accessing: https://kubernetes.docker.internal/. The admin user is created with the following credentials: `admin@kind.com / pass123456`

If you want to delete the cluster run:

```shell
make kind-delete-cluster
```