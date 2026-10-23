# homelab-k8s

A local Kubernetes lab for practising database reliability work the way it's done in production. It runs a three-instance highly available PostgreSQL cluster, managed by an operator, with Prometheus and Grafana watching it, all on a laptop.

It's built for exercises like these: kill the primary under load and watch the operator promote a replica, measure the failover window, and see what happens to in-flight transactions. Docker Compose can't do that realistically.

## What it runs

- **Colima** as the container runtime, instead of Docker Desktop.
- **k3d**, a k3s Kubernetes cluster in Docker, with 3 control-plane nodes and 2 agents.
- **CloudNativePG**, the PostgreSQL operator, in `cnpg-system`.
- **`pg-lab`**: a 3-instance PostgreSQL cluster in `databases`, with database `labdb` owned by `labuser`.
- **kube-prometheus-stack** (Prometheus, Grafana, Alertmanager) in `monitoring`, scraping the Postgres instances and the operator through PodMonitors.

## Requirements

macOS or Linux with `colima`, `k3d`, `kubectl` and `helm` installed. Colima is started with 4 CPUs and 8 GB of memory, which is about the minimum for everything above.

## Usage

```bash
./setup.sh      # start Colima, create the cluster, install the operator, Postgres and monitoring
./connect.sh    # port-forward Postgres (5432), Grafana (3000) and Prometheus (9090) to localhost
./teardown.sh   # delete the cluster and stop Colima
```

Connect to the primary:

```bash
kubectl get secret pg-lab-app -n databases -o jsonpath='{.data.password}' | base64 -d; echo
psql -h localhost -U labuser labdb
```

CloudNativePG generates the application user's password and stores it in the `pg-lab-app` secret. No credentials are kept in this repo.

## Notes

- **PodMonitors need `release: monitoring`.** kube-prometheus-stack's Prometheus only selects PodMonitors that carry that label. Without it, nothing is scraped and the dashboards stay empty.
- **`kubectl port-forward` is not a load-testing path.** It drops connections under sustained concurrent load, and the error looks like a database problem when it isn't. Run `pgbench` from a pod inside the cluster instead:

  ```bash
  kubectl run pgbench-client -n databases --rm -it --image=postgres:17 -- \
    pgbench -h pg-lab-rw -U labuser -c 10 -j 2 -T 60 -P 5 labdb
  ```

- **Failover test:** while `pgbench` runs, find the primary with `kubectl get cluster pg-lab -n databases`, then delete its pod. Watch the `PRIMARY` column change, and watch the old primary rejoin as a replica.

## Next steps

- PgBouncer in front of Postgres
- Prometheus alert rules for replication lag and lost replicas
- A backup and point-in-time restore drill
- MySQL with the Percona operator, for comparison
