# Boltz image for RunPod: Debian 13 from scratch, Python 3.12 via uv, latest Boltz from PyPI.
# Model weights are NOT baked in: Boltz downloads them on first run.
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH

# System tools. build-essential is needed because Triton/cuequivariance may compile kernels at runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git openssh-server tmux htop nano less procps \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# uv is used to get Python 3.12 (Debian 13 ships 3.13, which Boltz does not support).
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

RUN uv venv /opt/venv --python 3.12

# PyTorch with CUDA 12.8 (also works on Blackwell GPUs), then Boltz with its CUDA kernels extra.
RUN uv pip install --python /opt/venv/bin/python torch --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip install --python /opt/venv/bin/python "boltz[cuda]" \
    && uv cache clean

# Make the venv available in ssh sessions too (RunPod does not pass container env vars to ssh).
RUN echo 'export PATH=/opt/venv/bin:$PATH' > /etc/profile.d/venv.sh \
    && echo 'source /etc/profile.d/venv.sh' >> /root/.bashrc

COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /workspace
CMD ["/start.sh"]
