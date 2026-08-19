---
description: Provision an AWS GPU EC2 instance and bootstrap the GGUF LLM container from GitHub (drivers + llama-cpp-python CUDA)
argument-hint: "[instance-type] [region]   e.g. g6.xlarge ap-south-1"
allowed-tools: Bash, Read, AskUserQuestion
---

# /gpu-vm — AWS GPU VM + driver/container bootstrap from GitHub

Provision an AWS GPU EC2 instance, then bootstrap it from the GitHub repo
`https://github.com/KarneeshkarV/gpu-llm-vm-setup.git` (installs NVIDIA-aware
Python env, the prebuilt CUDA `llama-cpp-python` wheel, and CUDA runtime libs).

Arguments (optional): `$ARGUMENTS`
- arg 1 = instance type (default `g6.xlarge` — NVIDIA L4, ~22.5 GB VRAM)
- arg 2 = region (default `ap-south-1` / Mumbai)

## Fixed config (from the original working setup)

- AWS CLI profile: **`valura_pratiyush`** (always pass `--profile valura_pratiyush`)
- AMI: latest **"Deep Learning OSS Nvidia Driver AMI GPU PyTorch"** Ubuntu
  (driver-only, no `nvcc`; the repo's `setup.sh` is built for exactly this)
- Root volume: **50 GB** gp3
- SSH key: `~/.ssh/digital_ocean_har` (public key import as a new key pair if
  the named key pair does not already exist in the region). Passphrase: `ssh`
- Login user: `ubuntu`

## SAFETY — read before any AWS write call

1. This AWS account is a **shared Control Tower org account NOT owned by the
   user**. Every create/terminate is a real, billed, shared-blast-radius
   action. Before the FIRST write call, show the exact plan (instance type,
   region, AMI id, volume, est. $/hr) and get explicit user confirmation via
   AskUserQuestion. Do not proceed on assumed approval.
2. **Never** delete, stop, modify, or otherwise touch the pre-existing
   `t2.micro` instances `i-0ad680c37b1968503`, `i-077f15e5a8d00ae11`,
   `i-0e055d9e320d5f2dd`. Filter them out of every action explicitly.
3. Spot quota on this account is **0** → use **On-Demand** unless the user
   explicitly asks for Spot and confirms the quota was raised.
4. Tag everything you create with `Name=gpu-llm-vm` and
   `CreatedBy=claude-gpu-vm-cmd` so it is identifiable for later teardown.
5. State clearly that the instance bills until explicitly terminated, and
   remind the user to run `/gpu-vm` teardown (see end) when done.

## Steps

1. Parse `$ARGUMENTS`; resolve instance type + region (apply defaults).
   Confirm `aws --profile valura_pratiyush sts get-caller-identity` works.
2. Resolve the latest Deep Learning OSS Nvidia Driver AMI id via
   `aws ssm get-parameters` / `ec2 describe-images` in the target region.
3. Ensure a security group exists allowing inbound SSH (port 22) from the
   user's current public IP only. Ensure the key pair exists (import
   `~/.ssh/digital_ocean_har.pub` if missing).
4. Show the full plan + estimated hourly cost. **AskUserQuestion to confirm.**
5. On confirmation, `run-instances`: chosen type, AMI, 50 GB gp3, key pair,
   SG, On-Demand, with the Name/CreatedBy tags. Wait until `running` + status
   checks pass; capture the public IP.
6. SSH in (`ssh -i ~/.ssh/digital_ocean_har ubuntu@<ip>`, passphrase `ssh`;
   `StrictHostKeyChecking=accept-new`). Then on the VM:
   ```bash
   git clone https://github.com/KarneeshkarV/gpu-llm-vm-setup.git
   cd gpu-llm-vm-setup
   bash setup.sh
   ```
   `setup.sh` is idempotent and self-checks `nvidia-smi`, installs `uv`, the
   cu124 prebuilt `llama-cpp-python` wheel, and CUDA runtime libs.
7. Report: instance id, public IP, the SSH command, and that `bash run.sh` /
   `bash chat.sh` must be run by the user in a real foreground TTY (the model
   ~16 GB downloads once on first run). Restate the running-cost warning.

## Teardown (when invoked as `/gpu-vm teardown` or user asks to destroy)

Terminate **only** instances tagged `CreatedBy=claude-gpu-vm-cmd` (never the
3 protected t2.micros). Delete the key pair/SG only if this command created
them and nothing else uses them. Verify with a final `describe-instances`
that the GPU instance is `terminated`, then report the result.
