#!/bin/bash

# 1) Обновление системы
yum update -y

# 2) Установка и включение Firewalld (аналог UFW в CentOS)
yum install firewalld -y
systemctl start firewalld
systemctl enable firewalld

# 3) Создание нового пользователя и добавление его в группу sudo (wheel)
read -p "Введите имя нового пользователя: " new_user
adduser $new_user
echo "Введите пароль для нового пользователя:"
passwd $new_user
usermod -aG wheel $new_user

# 4) Генерация ключей SSH для нового пользователя и настройка авторизации по ключам
mkdir -p /home/$new_user/.ssh
chmod 700 /home/$new_user/.ssh
ssh-keygen -t rsa -b 2048 -f /home/$new_user/.ssh/id_rsa -N ""
cat /home/$new_user/.ssh/id_rsa.pub >> /home/$new_user/.ssh/authorized_keys
chmod 600 /home/$new_user/.ssh/authorized_keys
chown -R $new_user:$new_user /home/$new_user/.ssh

# 5) Изменение порта SSH, настройка безопасности и запрет аутентификации по паролю
read -p "Введите новый порт SSH: " sshport
sed -i "s/#Port 22/Port $sshport/" /etc/ssh/sshd_config
sed -i '/^PasswordAuthentication/ c\PasswordAuthentication no' /etc/ssh/sshd_config
sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config

# 6) Добавление нового порта в Firewalld и активация Firewalld
firewall-cmd --permanent --add-port=$sshport/tcp
firewall-cmd --reload

# 7) Отключение учетной записи root
sed -i 's|^root:x:.*:/bin/bash|root:x:0:0:root:/root:/usr/sbin/nologin|' /etc/passwd

# 8) Перезапуск сервиса SSH для применения изменений
systemctl restart sshd

# 9) Вывод приватного ключа нового пользователя
echo "Приватный ключ нового пользователя:"
cat /home/$new_user/.ssh/id_rsa
echo -e "\nНастройка завершена."
