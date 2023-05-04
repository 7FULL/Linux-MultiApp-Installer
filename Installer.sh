#!/bin/bash

function instalarApache() {
    sudo apt-get install apache2 -y

    echo ""
    read -p "Quieres borrar el archivo que viene por defecto con apache? y/n" option
    echo ""

    while [ $option != "y" ] && [ $option != "n" ]; do

        if [ $opcion == "y" ]; then
        rm /var/www/html/index.html
        fi

    done
}

function instalarPIHole() {
    #En principio curl viene instalao por defecto pero por si acaso
    sudo apt-get install curl

    echo ""
    echo "Lo recomendable es darle a todo enter no cambiar nada"
    echo ""

    sleep 5 && sudo curl -sSl https://install.pi-hole.net | bash

    while true; do
        read -p "Te ha fallado el FTL? y/n" respuesta

        if [$respuesta == y]; then

            echo ""
            #Realizado asi en vez de echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf para que el usuario no vea nada escrito       
            #Para evitar que se vea en la consola creamos una nueva instancia de la shell por lo que no se ve  
            sudo sh -c "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"

            echo ""
            echo "Lo recomendable es darle a todo enter no cambiar nada"
            echo ""

            sleep 5 && sudo curl -sSl https://install.pi-hole.net | bash

            echo ""
            
        elif [$respuesta == n]; then
            break;
        else
            echo "Respuesta no valida"
        fi
    done

    while true; do
        read -p "Quieres cambiar la contraseña de administrador? y/n" respuesta
        echo ""

        if [$respuesta == y]; then

            pihole -a -p
            
        elif [$respuesta == n]; then
            break;
        else
            echo "Respuesta no valida"
        fi
    done

    echo ""

    #Obtenemos ip para mostarle la pagina web
    ip=$(hostname -I | awk '{print $2}')

    echo ""
    echo "Ya puedes configurar lo que quieras en la pagina web. Solo visita este enlace $ip/admin"
}

function instalarMariaDB() {
    sudo apt-get install mariadb-server php-mysql -y

    while true; do
        read -p "Quieres ejecutar la instalacion de seguridad de sql? y/n" respuesta

        if [$respuesta == y]; then
            echo "Lo recomendable es Enter N Y(contraseña) Y N Y Y"

            sleep 5 && sudo mysql_secure_installation
            
        elif [$respuesta == n]; then
            break;
        else
            echo "Respuesta no valida"
        fi
    done

    while true; do
        read -p "Quieres que la base de datos emita por la ip de la raspberry? y/n" respuesta

        if [$respuesta == y]; then
            #Obtenemos la ip y con el awk obtenemos la segunda columna ya que la primera no nos interesa
            ip=$(hostname -I | awk '{print $2}')

            #echo ""
            #echo "La ip es: $ip"

            #Cambiamos del archivo de configuracion la bind-address a la ip de la raspberry para que emita por ahi
            sudo sed -i "s/bind-address\s*=.*/bind-address = $ip/" /etc/mysql/mariadb.conf.d/50-server.cnf
        elif [$respuesta == n]; then
            break;
        else
            echo "Respuesta no valida"
        fi
    done

    #Reiniciamos para que se apliquen cambios
    sudo systemctl restart mariadb
}

function instalarTomcat() {
    sudo apt-get install tomcat9 -y
}

function instalarPHP() {
    sudo apt install php -y
    sudo service apache2 restart
}

function instalarOPM(){
    
}

function instalarTodo(){
    instalarApache
    instalarPHP
    instalarMariaDB
    instalarTomcat
    instalarOPM
    instalarPIHole
}

function instalarPackDesarrolloWeb(){
    instalarApache
    instalarPHP
    instalarMariaDB
    instalarTomcat
}

function menuDeInstalaciones() {
    echo ""
    echo "Antes de instalar nada tenemos que actualizar los paquetes y el sistema"
    echo ""

    #El sleep para que el usuario le de tiempo a leerlo
    #sleep 5 && sudo apt-get update && sudo apt-get upgrade -y

    while true; do

        echo ""

        echo "Seleccione una opción:"
        echo "1. Instalar Apache"
        echo "2. Instalar PHP (se instalara tambien apache)"
        echo "3. Instalar PIhole (Solo debian)"
        echo "4. Instalar MariaDB"
        echo "5. Instalar Tomcat"
        echo "6. Instalar OpenMediaVault"
        echo "7. Instalar pack desarrollo web (PHP,Apache,MariaDB y Tomcat)"
        echo "8. Instalar todo"
        echo "9. Menu principal"

        echo ""

        read -p "Ingrese el número de opción que desea ejecutar: " option

        case $option in
            1) instalarApache;;
            2) instalarPHP;;
            3) instalarPIHole;;
            4) instalarMariaDB;;
            5) instalarTomcat;;
            6) instalarOPM;;
            7) instalarPackDesarrolloWeb;;
            8) instalarTodo;;
            9) break;;
            *) echo "Opción no válida";;
        esac
    done
}

function crearCarpeta() {
  #Si metes la ruta completa con el nombre tambien funciona y ademas se te crea en esa ruta obviamente
  read -p "Ingrese el nombre de la carpeta que desea crear: " folder_name

  while [ -d "$folder_name" ]; do

    read -p "El nombre de la carpeta ya existe. Ingrese otro nombre: " folder_name

  done

  #Comillas por si acaso el usuario mete espacios u otra cosa
  mkdir "$folder_name"

  echo "Carpeta creada correctamente"
}

function borrarCarpeta() {
  #Si metes la ruta completa con el nombre tambien funciona y ademas se te borra en esa ruta obviamente
  read -p "Ingrese el nombre de la carpeta que desea borrar: " folder_name
  
  while [ ! -d "$folder_name" ]; do

    read -p "La carpeta no existe. Ingrese otro nombre: " folder_name

  done

  #Comillas por si acaso el usuario mete espacios u otra cosa
  rm -rf "$folder_name"

  echo "Carpeta eliminada correctamente"
}

function menuPrincipal() {
    while $true; do
        echo ""

        echo "Seleccione una opción:"
        echo "1. Crear carpeta"
        echo "2. Borrar carpeta"
        echo "3. Instalador"
        echo "4. Salir"

        echo ""

        read -p "Ingrese el número de opción que desea ejecutar: " option        

        case $option in
            1)  crearCarpeta;;
            2)  borrarCarpeta;;
            3)  menuDeInstalaciones;;
            4)  exit;;
            *)  echo "Opción no válida";;
        esac
    done
}

menuPrincipal

#Por si ayuda a alguien

#  -a Si existe
#  -d Existe directorio
#  -f Existe fichero
#  -r Tiene permisos de lectura
#  -w Tiene permisos de escritura
#  -x Tiene permisos de ejecución
#  -z Está vacía
#  ...

#  -eq  =
#  -ne  !=
#  -lt  <
#  -gt  >
#  -le  <=
#  -ge  >=