#!/bin/bash

# Обновление системы
apt update
apt upgrade -y

# Установка UFW
apt install -y ufw

# 1. Создание нового пользователя и добавление в группу sudo
read -p "Введите имя нового пользователя: " new_user
adduser $new_user
usermod -aG sudo $new_user

# 2. Генерация ключей и авторизация по ключам
mkdir -p /home/$new_user/.ssh
chmod 700 /home/$new_user/.ssh
ssh-keygen -t rsa -b 2048 -f /home/$new_user/.ssh/id_rsa -N ""
cat /home/$new_user/.ssh/id_rsa.pub >> /home/$new_user/.ssh/authorized_keys
chmod 600 /home/$new_user/.ssh/authorized_keys
chown -R $new_user:$new_user /home/$new_user/.ssh

# 3. Изменение порта SSH и настройка безопасности
read -p "Введите новый порт для SSH: " new_ssh_port
sed -i "s/^#Port 22/Port $new_ssh_port/" /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# 4. Добавление нового порта в файерволл UFW
ufw allow $new_ssh_port
ufw enable

# 5. Отключение учетной записи root
sed -i 's|^root:x:.*:/bin/bash|root:x:0:0:root:/root:/usr/sbin/nologin|' /etc/passwd

# Перезапуск сервиса SSH для применения изменений
systemctl ssh restart
systemctl sshd restart

# Вывод приватного ключа
echo "Ваш приватный ключ для подключения к серверу:"
cat /home/$new_user/.ssh/id_rsa
echo -e "\nНастройка завершена."