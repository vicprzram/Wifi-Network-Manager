#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  clear
  echo "Run me as ROOT!!"
  exit 1
fi

errors () {
  echo "Error: $1, please try again"
}

newConnection () {
  clear
  echo -e "-- You have choosen: New connection --\n\n"
  read -p "File name: " fileName
  if [[ -f /etc/netctl/$fileName ]]; then
    errors "The inserted file name is already created"
  else
    read -p "Connection name (ESSID): " ESSID
    read -p "Password: " password
    
    echo -e "Description='A simple WPA encrypted wireless connection'\nInterface=wlan0\nConnection=wireless\n\nSecurity=wpa\nIP=dhcp\n\nESSID='$ESSID'\nKey='$password'" > /etc/netctl/$fileName
    echo "Your file has been created successfully"
    sleep 5
  fi
}

connect () {
  clear
  echo -e "-- You have choosen: Connect with existing file --\n\n"

  read -p "Do you want to list all the files? (y/n): " userConnection
  if [[ $userConnection = yes ]] || [[ $userConnection = y ]]; then
    ls /etc/netctl | grep -v examples | grep -v hooks | grep -v interfaces
    echo -e "\n"
  else
    :
  fi

  read -p "Name of the file to connect: " fileName
  if [[ -f /etc/netctl/$fileName ]]; then
    ip link set wlan0 down
    netctl stop-all
    netctl start $fileName
    echo "You have been connected successfully"
  else
    errors "This file name doesn't exist"
  fi
  sleep 5
}

connectionManager () {
  clear
  echo -e "-- You have choosen: Connection manager --\n\n"

  ls /etc/netctl | grep -v examples | grep -v hooks | grep -v interfaces > delete
  
  counter=0
  while IFS= read -r line 
  do
    ((counter++))
    echo "$counter - $line"
  done < delete
  
  ((counter++))
  echo "$counter - Stop all"
  
  lineSize=$counter

  echo -e "\n"
  read -p "Your option: " userOption
  if [[ $userOption -eq $lineSize ]]; then
    netctl stop-all
    echo "Your stop-all has been successfully executed"
  elif [[ $userOption -gt $lineSize ]]; then
    errors "This option in not valid"
  else
    counter=0
    while IFS= read -r line
    do
      ((counter++))
      if [[ $counter -eq $userOption ]]; then
        break 
      fi
    done < delete
   

    while :; do
      clear
      echo -e "-- Choose an option for $line--\n1 - Start\n2 - Stop\n3 - Restart\n4 - Status\n5 - Quit to Main menu"
      read -p "Your option: " userOption
      case $userOption in
        1)
          netctl start $line
          ;;
        2)
          netctl stop $line
          ;;
        3)
          netctl restart $line
          ;;
        4)
          netctl status $line
          ;;
        5)
          break 
          ;;
        *)
          errors "Option not valid"
          ;;
      esac
    done
  fi
  sleep 5
}

listFile () {
  clear
  echo -e "-- You have choosen: List files --\n\n"
  ls /etc/netctl | grep -v examples | grep -v hooks | grep -v interfaces
  sleep 5
}

removeFile () {
  clear
  echo -e "-- Files --\n\n"
  ls /etc/netctl | grep -v examples | grep -v hooks | grep -v interfaces
  echo -e "\n"
  read -p "Name of the file: " file
  if [[ -f /etc/netctl/$file ]]; then
    rm /etc/netctl/$file
    echo "Your file has been deleted successfully"
  else
    errors "Inserted file not found"
  fi
  sleep 5
}

restartService () {
  clear
  systemctl restart NetworkManager.service
  echo "Your NetworkManager has been restarted succesfully"
  sleep 5
}

while :; do
  clear
  echo -e "-- Choose an option --\n1 - New connection\n2 - Connect with existing file\n3 - Connection manager\n4 - List files\n5 - Remove file\n6 - Restart NetworkManager\n7 - Scan networks\n8 - Exit"
  
  read -p "Your option: " Option
  case "$Option" in
    1) 
      newConnection
      ;;
    2)
      connect
      ;;
    3)
      connectionManager
      ;;
    4)
      listFile
      ;;
    5)
      removeFile
      ;;
    6)
      restartService
      ;;
    7)
      clear
      nmcli device wifi list
      ;;
    8)
      if [[ -d "delete" ]]; then
        rm delete
      fi
      break
      ;;
    *)
      clear
      errors "This argument is not valid"
      ;;
  esac
done
