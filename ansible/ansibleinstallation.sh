#!/bin/bash

#######################################
# Configurable Variables
#######################################
PEM_KEY_PATH="/home/ec2-user/LightsailDefaultKey-us-west-2.pem"   # Update if needed
MANAGED_NODES=("35.94.251.216" "54.190.175.22")   # Add/remove IPs as needed

#######################################
# Step 1: Update system packages
#######################################
echo "[+] Updating system packages..."
sudo dnf update -y

#######################################
# Step 2: Install Python3 and pip
#######################################
echo "[+] Installing Python3 and pip..."
sudo dnf install -y python3 python3-pip

#######################################
# Step 3: Install Ansible
#######################################
echo "[+] Installing Ansible..."
sudo pip3 install ansible

#######################################
# Step 4: Create Ansible directories & files
#######################################
echo "[+] Creating /etc/ansible structure..."
sudo mkdir -p /etc/ansible
sudo touch /etc/ansible/hosts
sudo touch /etc/ansible/ansible.cfg

#######################################
# Step 5: Generate SSH key pair (if missing)
#######################################
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "[+] Generating SSH key pair..."
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -q -N ""
else
    echo "[+] SSH key already exists."
fi

#######################################
# Step 6: Copy SSH key to managed nodes
#######################################
echo "[+] Copying SSH key to managed nodes..."
for ip in "${MANAGED_NODES[@]}"; do
    echo "    -> Setting up SSH trust for $ip"
    ssh -o StrictHostKeyChecking=no -i "$PEM_KEY_PATH" ec2-user@"$ip" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo $(cat ~/.ssh/id_rsa.pub) >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
done

#######################################
# Step 7: Configure Ansible inventory
#######################################
echo "[+] Writing inventory to /etc/ansible/hosts..."
sudo bash -c 'cat > /etc/ansible/hosts' << EOF
[web]
54.190.175.22

[db]
35.94.251.216

[all:vars]
ansible_user=ec2-user
ansible_python_interpreter=/usr/bin/python3
EOF

#######################################
# Step 8: Configure ansible.cfg
#######################################
echo "[+] Writing Ansible configuration..."
sudo bash -c 'cat > /etc/ansible/ansible.cfg' << EOF
[defaults]
inventory = /etc/ansible/hosts
host_key_checking = False
remote_user = ec2-user
deprecation_warnings = False
EOF

#######################################
# Step 9: Validate Ansible connectivity
#######################################
echo "[+] Validating Ansible connection to all nodes..."
ansible all -m ping
echo "[✓] Ansible Controller and Managed Nodes configured successfully!"

echo "[✓] Ansible Controller and Managed Nodes configured successfully!"
