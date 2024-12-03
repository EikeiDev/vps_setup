#!/bin/bash

# 1) Обновление системы
apt-get update && apt full-upgrade -y && apt autoremove -y

# 2) Установка UFW (Uncomplicated Firewall) и bc
apt-get install ufw bc -y

# 3) Создание нового пользователя и добавление его в группу sudo
read -p "Введите имя нового пользователя: " new_user
adduser $new_user
usermod -aG sudo $new_user

# 4) Генерация ключей SSH для нового пользователя и настройка авторизации по ключам
mkdir -p /home/$new_user/.ssh
chmod 700 /home/$new_user/.ssh
ssh-keygen -t ed25519 -f /home/$new_user/.ssh/id_ed25519 -N ""
cat /home/$new_user/.ssh/id_ed25519.pub > /home/$new_user/.ssh/authorized_keys
chmod 600 /home/$new_user/.ssh/authorized_keys
chown -R $new_user:$new_user /home/$new_user/.ssh

# 5) Изменение порта SSH, настройка безопасности и настройки аутентификации
os_version=$(lsb_release -sr)
if (( $(echo "$os_version >= 22.10" | bc -l) )); then
    read -p "Введите новый порт SSH для Ubuntu 22.10 и выше: " sshport
    sed -i "s/ListenStream=.*/ListenStream=$sshport/" /lib/systemd/system/ssh.socket
    systemctl daemon-reload
    systemctl restart ssh.socket
else
    read -p "Введите новый порт SSH для Ubuntu ниже 22.10: " sshport
    sed -i "s/#Port 22/Port $sshport/" /etc/ssh/sshd_config
    systemctl restart ssh
fi

# Активация изменений параметров PasswordAuthentication PermitRootLogin PubkeyAuthentication
sed -i -e '/^#PasswordAuthentication/ c\PasswordAuthentication no' \
       -e '/^PasswordAuthentication/ c\PasswordAuthentication no' \
       -e '/^#PermitRootLogin/ c\PermitRootLogin no' \
       -e '/^PermitRootLogin/ c\PermitRootLogin no' \
       -e '/^#PubkeyAuthentication/ c\PubkeyAuthentication yes' /etc/ssh/sshd_config

# Создание файла /etc/ssh/sshd_config.d/50-cloud-init.conf и добавление параметра PasswordAuthentication
echo "PasswordAuthentication no" > /etc/ssh/sshd_config.d/50-cloud-init.conf

# 6) Добавление нового порта в файерволл UFW и активация UFW
ufw allow $sshport/tcp
ufw enable

# 7) Отключение учетной записи root
usermod -s /usr/sbin/nologin root

# 8) Перезапуск сервиса SSH для применения изменений
systemctl restart ssh

# 9) Вывод приватного ключа нового пользователя
echo "Приватный ключ нового пользователя:"
cat /home/$new_user/.ssh/id_ed25519
echo -e "\nНастройка завершена."
