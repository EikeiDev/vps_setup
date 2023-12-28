#!/bin/bash

# 1) Обновление системы
apt update && apt upgrade -y

# 2) Установка UFW (Uncomplicated Firewall)
apt install ufw -y

# 3) Создание нового пользователя и добавление его в группу sudo
read -p "Введите имя нового пользователя: " new_user
adduser $new_user
usermod -aG sudo $new_user

# 4) Генерация ключей SSH для нового пользователя и настройка авторизации по ключам
mkdir -p /home/$new_user/.ssh
chmod 700 /home/$new_user/.ssh
ssh-keygen -t rsa -b 2048 -f /home/$new_user/.ssh/id_rsa -N ""
cat /home/$new_user/.ssh/id_rsa.pub >> /home/$new_user/.ssh/authorized_keys
chmod 600 /home/$new_user/.ssh/authorized_keys
chown -R $new_user:$new_user /home/$new_user/.ssh

# 5) Изменение порта SSH, настройка безопасности и настройки аутентификации
os_version=$(lsb_release -sr)
if (( $(echo "$os_version >= 23.04" | bc -l) )); then
    read -p "Введите новый порт SSH для Ubuntu 23.04 и выше: " sshport
    sed -i "s/ListenStream=.*/ListenStream=$sshport/" /lib/systemd/system/ssh.socket
    systemctl daemon-reload
    systemctl restart ssh.socket
else
    read -p "Введите новый порт SSH для Ubuntu ниже 23.04: " sshport
    sed -i "s/#Port 22/Port $sshport/" /etc/ssh/sshd_config
    systemctl restart ssh
fi

# Раскомментирование и установка параметра PubkeyAuthentication
sed -i '/^#PubkeyAuthentication/ c\PubkeyAuthentication yes' /etc/ssh/sshd_config

# Активация изменений параметров PasswordAuthentication и PermitRootLogin
sed -i '/^#PasswordAuthentication/ c\PasswordAuthentication no' /etc/ssh/sshd_config
sed -i '/^PasswordAuthentication/ c\PasswordAuthentication no' /etc/ssh/sshd_config
sed -i '/^#PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config

# Создание файла /etc/ssh/sshd_config.d/50-cloud-init.conf и добавление параметра PasswordAuthentication
echo "PasswordAuthentication no" > /etc/ssh/sshd_config.d/50-cloud-init.conf

# 6) Добавление нового порта в файерволл UFW и активация UFW
ufw allow $sshport/tcp
ufw enable

# 7) Отключение учетной записи root
sed -i 's|^root:x:.*:/bin/bash|root:x:0:0:root:/root:/usr/sbin/nologin|' /etc/passwd

# 8) Перезапуск сервиса SSH для применения изменений
systemctl restart ssh

# 9) Вывод приватного ключа нового пользователя
echo "Приватный ключ нового пользователя:"
cat /home/$new_user/.ssh/id_rsa

# Вывод сообщения о завершении настройки
echo -e "\nНастройка завершена."
