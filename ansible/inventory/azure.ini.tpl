# ansible/inventory/azure.ini.tpl
[jenkins]
jenkins-vm ansible_host=${vm_ip}

[jenkins:vars]
ansible_user=${admin_username}
ansible_ssh_private_key_file=${ssh_key_path}
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'