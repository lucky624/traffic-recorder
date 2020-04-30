#!/bin/bash

if [ $USER != "root" ];then
        echo "Run script with root privileges"
        exit
fi

check_os=$(uname -v)
os=unknown
docker_version=$(docker -v)


if echo "$check_os" | grep -o "Ubuntu" > /dev/null ;then
	os=Ubuntu

elif echo "$check_os" | grep -o "Debian" > /dev/null;then
	os=Debian
else
	echo "Unknown OS"
        exit
fi


while :
do
  current_ls=$(ls -l | grep '^d')
  if [ "$current_ls" != "" ];then
  	while :
  	do
  	clear
      echo "$(tput setaf 6) RECORDER $(tput sgr 0)"
      echo ""
  		echo "   1) Add record service"
  		echo "   2) Manage"
  		echo "   3) Exit"
  		read -p "Select an option: " option
  		until [[ "$option" =~ ^[1-3]$ ]]; do
  			echo "$option: invalid selection."
  			read -p "Select an option: " option

  		done
  		case "$option" in
  			1)
  			clear
  			read -p "Service name : " name
  			until echo "$name" | egrep "^[a-z_]+$" ; do
  				echo "Str must be ^[a-z_]+$."
  				read -p "Service name: " name
  			done
  			clear

  			read -p "Port : " port
  			until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
  				echo "$port: invalid selection."
  				read -p "Port : " port
  			done
  			clear

  			mkdir $name
  			echo "$port" > $name/port
        echo "off" > $name/status


  			;;
  			2)
        while :
        do
          clear
          PERIOD=$(cat config | grep -oP "(?<=PERIOD=)\d+")
          INTERFACE_NAME=$(cat config | grep -oP "(?<=INTERFACE_NAME=)\w+")
          CONTAINER_NAME=$(cat config | grep -oP "(?<=CONTAINER_NAME=)\w+")
          PERMANENT_PORT=$(cat config | grep -oP "(?<=PERMANENT_PORT=)\d+")
          echo "$(tput setaf 6) RECORDER $(tput sgr 0)"
          echo ""
    			counter=1
    			services=$(ls -d */)
    			for i in $services;do
            check_container=$(docker ps -q --no-trunc -f name=record)
            if [ "$check_container" == "" ];then
              cat_port=$(cat ${i%%/}/port)
              echo "$counter) ${i%%/} [$cat_port] - $(tput setaf 1)no record $(tput sgr 0)"
              counter=$((counter+1))
              continue
            fi

    				ports_in_command=$(docker ps -a --no-trunc -f name=record | grep -oE "port.+\"")
            cat_port=$(cat ${i%%/}/port)
            check_port=$(echo "$ports_in_command" | grep -oE "$cat_port")
    				if [ "$check_port" != "" ];then
    					echo "$counter) ${i%%/} [$cat_port] - $(tput setaf 2)is recording $(tput sgr 0)"
    				else
    					echo "$counter) ${i%%/} [$cat_port] - $(tput setaf 1)no record $(tput sgr 0)"
    				fi
    				counter=$((counter+1))
    			done
    			counter=$((counter-1))

    			read -p "Select an service: " service

          if [ "$service" == "" ];then
            continue
          fi

          if [ "$service" == "q" ];then
            break
          fi
          until [[ "$service" != "" && "$service" =~ ^[0-9]+$ && "$service" -le $counter && "$service" -gt 0 ]]; do
    				echo "$service: invalid selection."
    				read -p "Select an service: : " service
    			done

          counter=1
          for i in $services;do
            if [ $service -eq $counter ] ;then
              srv="${i%%/}"
            fi
            counter=$((counter+1))
          done

          clear
          echo "$(tput setaf 6)$srv $(tput sgr 0)"
          echo "1) Start record"
          echo "2) Exclude"
          echo "3) Edit"


          read -p "Select an action  : " status
          until [[ "$status" =~ ^[1-3]$ ]]; do
            if [ "$status" == "" ];then
              break
            fi
            echo "$status: invalid selection."
      			read -p "Select an status: " status
          done

          if [ "$status" == "1" ];then
            check_container=$(docker ps -q --no-trunc -f name=record)
            ports_in_command=$(docker ps -a --no-trunc -f name=record | grep -oE "port.+\"")
            cat_port=$(cat $srv/port)
            check_port=$(echo "$ports_in_command" | grep -oE "$cat_port")
            if [ "$check_container" != "" ];then
              if [ "$check_port" != "" ];then
                echo ""
                echo "Service $use_port is recording"
                sleep 2
                continue
              fi
            fi
            echo "on" > $srv/status
            docker stop record &> /dev/null
            docker rm record &> /dev/null


            done_string=""
            template_command="docker run --net=host --name $CONTAINER_NAME -d -v $PWD:/data corfr/tcpdump -G $PERIOD -t -nn -S -i $INTERFACE_NAME -w /data/%H:%M:%S.pcap port $PERMANENT_PORT"
            services=$(ls -d */)
            for b in $services;do
              cat__port=$(cat ${b%%/}/port)
              cat__status=$(cat ${b%%/}/status)
              if [ "$cat__status" == "on" ];then
                done_string+=" or port $cat__port"
              fi
            done
            template_command+=$done_string
            bash -c "$(echo $template_command)"

          elif [ "$status" == "2" ];then
           echo "off" > $srv/status
           docker stop record &> /dev/null
           docker rm record &> /dev/null

           done_string=""
           template_command="docker run --net=host --name $CONTAINER_NAME -d -v $PWD:/data corfr/tcpdump -G $PERIOD -t -nn -S -i $INTERFACE_NAME -w /data/%H:%M:%S.pcap port $PERMANENT_PORT"
           services=$(ls -d */)
           have_any="no"
           for b in $services;do
             cat__port=$(cat ${b%%/}/port)
             cat__status=$(cat ${b%%/}/status)
             if [ "$cat__status" == "on" ];then
               done_string+=" or port $cat__port"
               have_any="yes"
             fi
           done
           if [ "$have_any" == "yes" ];then
             template_command+=$done_string
             bash -c "$(echo $template_command)"
           else
             docker stop record &> /dev/null
             docker rm record &> /dev/null
           fi

         elif [ "$status" == "3" ];then
           read -p "Port : " port
     			  until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
     				echo "$port: invalid selection."
     				read -p "Port : " port
     			 done
           echo "$port" > $srv/port
         fi
        done
        ;;
  			3)
  			exit ;;
  		esac
  	done
  else
  	if echo "$docker_version" | grep 'version' > /dev/null;then
      check_image=$(docker images | grep corfr/tcpdump)
      if [ "$check_image" == "" ];then
        echo "docker pull corfr/tcpdump"
        exit
      fi
      echo "$(tput setaf 6) RECORDER $(tput sgr 0)"
      echo ""
  		echo "   1) Add record service"
  		echo "   2) Exit             "
  		read -p "Select an option: " option
  		until [[ "$option" =~ ^[1-2]$ ]]; do
  			echo "$option: invalid selection."
  			read -p "Select an option: " option
  		done
      case "$option" in
        1)
        clear
        read -p "Service name : " name
        until echo "$name" | egrep "^[a-z_]+$" ; do
          echo "Str must be ^[a-z_]+$."
          read -p "Service name: " name
        done
        clear

        read -p "Port : " port
        until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
          echo "$port: invalid selection."
          read -p "Port : " port
        done
        clear

        mkdir $name
        echo "$port" > $name/port
        echo "off" > $name/status

        ;;
        2)
        exit ;;
      esac
  	else
  		echo "Docker is not installed on your system"
  		exit
  	fi
  fi
done
