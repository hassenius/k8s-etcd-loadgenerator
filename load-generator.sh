#!/bin/bash
pods_per_worker=30

echo "Getting number of worker nodes"
workers=( $(kubectl get nodes -l master!=true,management!=true,proxy!=true | awk 'NR>1 { print $1 }'))

echo "Found ${#workers[@]} workers"
echo "Workers: ${workers[@]}"


echo "Starting ${pods_per_worker} pods per worker"
npods=$(expr ${#workers[@]} \* ${pods_per_worker})

cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: ${npods}
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

echo "Waiting for deployment to complete"
sleep 1s
readyPods=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.readyReplicas}')
while [[ ${readyPods} -lt ${npods} ]]
do
  echo "Still waiting. Currently ready: ${readyPods:-0} Wanting ${npods}"
  sleep 1s
  readyPods=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.readyReplicas}')
done

echo "Deployment complete."

echo "Starting draining off one node at the time to stress etcd"
for worker in ${workers[@]}
do
  echo "Draining ${worker}"
  kubectl drain --ignore-daemonsets --grace-period=15 ${worker}
  echo "Drain complete"
  kubectl describe node ${worker}
  echo "Now putting node back into service"
  kubectl uncordon ${worker}
done
