#!/bin/bash
# RunPod entrypoint: enable ssh with the public key RunPod passes in, then keep the pod alive.
set -e

mkdir -p /root/.ssh /run/sshd
chmod 700 /root/.ssh

# RunPod provides the key of the account in PUBLIC_KEY.
if [ -n "$PUBLIC_KEY" ]; then
    echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi

# Export RunPod env vars so they are also visible in ssh sessions.
printenv | grep -E '^(RUNPOD_|CUDA_|NVIDIA_|LD_LIBRARY_PATH)' | sed 's/^/export /' > /etc/rp_environment
echo 'source /etc/rp_environment' >> /root/.bashrc

ssh-keygen -A
/usr/sbin/sshd

# Keep the container running.
sleep infinity
