#!/bin/bash

# Проверяем существует ли конфигурационный файл SElinux
if [[ ! -e /etc/selinux/config ]]; then
        echo "Сonfiguration file not found!"
        exit 1
fi
# Определяем ID пользователя под которым запущен скрипт
USERID=$(id -u)
# Получаем статус и режим работы службы
SESTATUS=$(sestatus | awk '/SELinux status:/ {print $3}')
SEMODE=$(getenforce)

echo "SELinux is $SESTATUS"

echo "SELinux mode is $SEMODE"

# Проверяем что пользователь с ID root иначе сообщаем что скрипт в режиме только вывода информации и завершаем выполнение
if [ "$USERID" = "0" ]; then
        echo
else
        echo
        echo "You are currently in read-only mode. To change the state, run as root"
        exit 0
fi

# Определяем какой режим работы установлен сейчас и в зависимости от результата подставляем вопрос о смене режима работы
# Так же подставляем нужную команду
case "$SEMODE" in
        Permissive)
        QUESTION="Set Enforcing mode? Y/N: "
        COMAND_MODE="setenforce Enforcing"
        ;;
        "Enforcing")
        QUESTION="Set Permissive mode? Y/N: "
        COMAND_MODE="setenforce Permissive"
        ;;
esac

# Выводим на экран предложение сменить режим работы, если ответ положительный, то выполняем команду из блока case выше
if [[ -n "$QUESTION" ]]; then
        read -p "$QUESTION" ANSWER
        if [[ $ANSWER == "Y" || $ANSWER == "y" ]]; then
                $COMAND_MODE
                echo "Mode changed"
                echo "Current mode: $(getenforce)"
                echo ""
        fi
fi


# Запрашиваем о внесении изменений в конфигурационный файл
read -p "Do you want to change config SELinux state?? Y/N: " ANSWER
if [[ $ANSWER != "Y" && $ANSWER != "y" ]]; then
        exit 0
fi

# Если на предыдущем шаге ответ был положительный, то предлагаем необходмый вариант
read -p "Select SELinux mode ( e - enforcing, p - permissive, d - disabled ): " ANSWER_MODE
echo
case "$ANSWER_MODE" in
        [eE])
        SELECTED_MODE="enforcing"
        ;;

        [pP])
        SELECTED_MODE="permissive"
        ;;

        [dD])
        SELECTED_MODE="disabled"
        ;;

        *)
        echo "$ANSWER_MODE - Incorrect parameter"
        exit 0
        ;;
esac

# Меняем в конфигурационном файле значение
sed -i "s/SELINUX=.*/SELINUX=${SELECTED_MODE}/g" /etc/selinux/config

echo "Reboot the system to apply the changes"
