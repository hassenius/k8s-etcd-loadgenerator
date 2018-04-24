# Simple load generator for kubernetes

How to run

1. Make sure you have kubectl installed and network access to the kubernetes cluster
1. Make sure you're logged into kubernetes (i.e. you get response from kubectl get pods)
1. Run generateConfigMaps.sh (leave running)
1. Run load-generator.sh


load-generator.sh will spin up a given amount of pods per node (default 30), and then evacuate and uncordon one node at the time. This simulates behaviour you might see when worker nodes are put in maintenance mode (or replaced) in a cyclical manner.
It also places a fair amount of strain on the ETCD cluster.

If you do not have a large amount of worker nodes you can loop through the load generator script with something like

```
for i in $( seq 1 10 ) ; do ./load-generator.sh ; done
```

