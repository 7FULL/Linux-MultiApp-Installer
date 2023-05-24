#!/bin/bash

#
#
# @Author: Pablo Hermida Gómez
#
#

function instalarApache() {
    echo ""
    echo "Instalando apache"
    echo ""

    sudo apt-get install apache2 -y

    echo ""
    read -p "Quieres borrar el archivo que viene por defecto con apache? y/n" option
    echo ""

    if [ $option == y ]; then
            sudo rm /var/www/html/index.html
    fi

    while true; do
        echo ""
        read -p "Quieres que apache se inicie con el sistema y/n" bootStart
        echo ""

        if [ $bootStart == y ]; then
            sudo systemctl enable apache2
            break
        elif [ $bootStart == n ]; then
            break
        else
            echo "Respuesta no valida"
        fi
    done

    #reiniciamos para que se apliquen cambios
    sudo service apache2 restart

    echo ""
    echo "Apache instalado correctamente"
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

        if [ $respuesta == y ]; then

            echo ""
            #Realizado asi en vez de echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf para que el usuario no vea nada escrito       
            #Para evitar que se vea en la consola creamos una nueva instancia de la shell por lo que no se ve  
            sudo sh -c "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"

            echo ""
            echo "Lo recomendable es darle a todo enter no cambiar nada"
            echo ""

            sleep 5 && sudo curl -sSl https://install.pi-hole.net | bash

            echo ""
            
        elif [ $respuesta == n ]; then
            break
        else
            echo "Respuesta no valida"
        fi
    done

    while true; do
        read -p "Quieres cambiar la contraseña de administrador? y/n" respuesta
        echo ""

        if [ $respuesta == y ]; then

            pihole -a -p
            
        elif [ $respuesta == n ]; then
            break
        else
            echo "Respuesta no valida"
        fi
    done

    echo ""

    ip=$(hostname -I)

    echo ""
    echo "PiHole instalado correctamente"
    echo ""
    echo "Ya puedes configurar lo que quieras en la pagina web. Solo visita este enlace http://$ip/admin"
}

function instalarMariaDB() {
    echo ""
    echo "Instalando mariadb"
    echo ""
    
    sudo apt-get install mariadb-server php-mysql -y

    while true; do
        read -p "Quieres ejecutar la instalacion de seguridad de sql? y/n" respuesta

        if [ $respuesta == y ]; then
            echo "Lo recomendable es Enter N Y(contraseña) Y N Y Y"

            sleep 5 && sudo mysql_secure_installation
            
        elif [ $respuesta == n ]; then
            break
        else
            echo "Respuesta no valida"
        fi
    done

    while true; do
        read -p "Quieres que la base de datos emita por la ip de la raspberry? y/n" respuesta

        if [ $respuesta == y ]; then
            echo ""
            echo "Cambiando la bind-address del servidor a la ip de la raspberry"

            #Obtenemos la ip y con el awk obtenemos la segunda columna ya que la primera no nos interesa
            ip=$(hostname -I)

            #echo ""
            #echo "La ip es: $ip"

            #Cambiamos del archivo de configuracion la bind-address a la ip de la raspberry para que emita por ahi
            sudo sed -i "s/bind-address\s*=.*/bind-address = $ip/" /etc/mysql/mariadb.conf.d/50-server.cnf

            break
        elif [ $respuesta == n ]; then
            break
        else
            echo "Respuesta no valida"
        fi
    done

    while true; do
        echo ""
        read -p "Quieres que mariadb se inicie con el sistema y/n" bootStart
        echo ""

        if [ $bootStart == y ]; then
            sudo systemctl enable mariadb
            break
        elif [ $bootStart == n ]; then
            break
        else
            echo "Respuesta no valida"
        fi
    done

    #Reiniciamos para que se apliquen cambios
    sudo systemctl restart mariadb

    echo "Mariadb instalado correctamente"
}

function instalarTomcat() {
    while true; do

        echo ""
        echo "1. Instalar Tomcat 9"
        echo "2. Instalar Tomcat 10"
        echo "3. Instalar version personalizada"
        echo "4. Salir"

        echo ""
        read -p "Qué versión de Tomcat quieres instalar? " opcion
        echo ""

        if [ $opcion != 4 ]; then
            # Aunque ya deberian de venir instalados por si acaso los instalamos
            echo "Instalando los jdk de java"
            echo ""
            sudo apt install default-jdk wget
        fi

        sudo mkdir -p /opt/tomcat

        case $opcion in
            1)  echo "Instalando tomcat9"  
                sudo apt-get install tomcat9 -y;;

            2)  echo "Instalando tomcat10"  
                wget https://downloads.apache.org/tomcat/tomcat-10/v10.1.8/bin/apache-tomcat-10.1.8.tar.gz
                sudo tar -xzf apache-tomcat-10.1.8.tar.gz -C /opt/tomcat --strip-components=1;;

            3)  echo ""
                read -p "Escribe la version concreta ejemplo: 10.0.14 o 9.2.13? " version
                echo ""

                echo "Intentando instalar la version $version"

                #Cortamos y comprobamos que version es para meterla en la url y cortarla en caso de que meta cualquier version anterior a 10
                versionPrevia=${version:0:2}

                if [ ${versionPrevia:1:1} == "." ]; then
                    versionPrevia=${versionPrevia:0:1}
                fi

                echo ""
                sleep 5 && wget https://downloads.apache.org/tomcat/tomcat-$versionPrevia/$version/bin/apache-tomcat-$version.tar.gz
                sudo tar -xzf apache-tomcat-$version.tar.gz -C /opt/tomcat --strip-components=1;;

            4)  break;;
            *)  echo "Opción no válida";;
        esac

        while true; do
            echo ""
            read -p "Quieres habilitar el acceso remoto al servidor para todos los clientes en la red? y/n" accesoRemoto
            echo ""

            if [ $accesoRemoto == y ]; then
                # Modificamos el archivo de configuración server.xml para habilitar el acceso remoto
                sudo sed -i 's/<Connector port="8080"/<Connector address="0.0.0.0" port="8080"/g' /opt/tomcat/conf/server.xml;
                break
            elif [ $accesoRemoto == n ]; then
                break
            else
                echo "Respuesta no valida"
            fi
        done



        #Futura funcionlidad, solo es una buena practica no afecta a la instalación. Solo crea un usuario especifico para darle permisos únicos de tomcat

        # Creamos el usuario tomcat y le damos permisos sobre el directorio de instalación de Tomcat
        #sudo useradd -r tomcat
        #sudo chown -R tomcat: /opt/tomcat



        #Damos permisos de ejecución a todos los archivos en bin ya que ahí están él startup y él stop y aveces es necesario ejecutarlos
        chmod +x /opt/tomcat/bin/*.sh

        while true; do
            echo ""
            read -p "Quieres crear un usuario de administración? y/n" usuariosAdministracion

        if [ $usuariosAdministracion == y ]; then
                echo ""
                echo "Escribe el nombre de usuario y contraseña para el usuario de administración"
                echo ""
                read -p "Nombre de usuario: " usuario
                read -p "Contraseña: " contrasena
                # Modificamos el archivo de configuración tomcat-users.xml para agregar un usuario con permisos de administración
                sudo sed -i '/<\/tomcat-users>/ i\
                <role rolename="manager-gui"/>\
                <role rolename="admin-gui"/>\
                <user username="'$usuario'" password="'$contrasena'" roles="admin-gui,manager-gui"/>\
                ' /opt/tomcat/conf/tomcat-users.xml
                break
            elif [ $usuariosAdministracion == n ]; then
                break
            else
                echo "Respuesta no valida"
            fi
            
        done

        while true; do
            echo ""
            read -p "Quieres habilitar el acceso remoto al administradorWeb desde fuera del localhost? y/n" accesoRemoto
            echo ""

            if [ $accesoRemoto == y ]; then
                # Modificamos el archivo con 2 sed ya que la sentencia del medio tiene caracteres raros
                sudo sed -i 's/<Valve/<!-- <Valve/g' /opt/tomcat/webapps/manager/META-INF/context.xml
                sudo sed -i 's/<Mana/--> <Mana/g' /opt/tomcat/webapps/manager/META-INF/context.xml

                # Modificamos el archivo con 2 sed ya que la sentencia del medio tiene caracteres raros
                sudo sed -i 's/<Valve/<!-- <Valve/g' /opt/tomcat/webapps/host-manager/META-INF/context.xml
                sudo sed -i 's/<Mana/--> <Mana/g' /opt/tomcat/webapps/host-manager/META-INF/context.xml
                break
            elif [ $accesoRemoto == n ]; then
                break;
            else
                echo "Respuesta no valida"
            fi
        done

        while true; do
            echo ""
            read -p "Quieres que el tomcat se inicie con el sistema y/n" bootStart
            echo ""

            if [ $bootStart == y ]; then
                sudo systemctl enable tomcat
                break
            elif [ $bootStart == n ]; then
                break;
            else
                echo "Respuesta no valida"
            fi
        done

        # Reiniciamos el servicio para que se apliquen los cambios
        sudo systemctl restart tomcat

        sudo bash /opt/tomcat/bin/startup.sh

        echo ""
        echo "Tomcat $version instalado correctamente."
        echo ""
    done
}

function instalarPHP() {
    echo ""
    echo "Instalando php"
    echo ""

    sudo apt install php -y

    sudo service apache2 restart

    echo ""

    echo "PHP instalado correctamente"
}

function instalarOPM(){
    echo ""
    echo "Instalando openMediaVault"
    echo ""

    sudo wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash

    ip=$(hostname -I)

    echo ""
    echo "OPM instalado correctamente"
    echo ""
    echo "Puedes acceder al administrador web con esta url http://$ip/#/login"
}

function instalarPHPMyAdmin(){
    instalarPHP
    instalarMariaDB

    sudo apt install phpmyadmin -y
    sudo phpenmod mysqli
    sudo service apache2 restart
    
    #Si no se mueve a la carpeta del apache pues no se ve
    sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
}

function instalarTodo(){
    instalarApache
    instalarPHP
    instalarMariaDB
    instalarPHPMyAdmin
    instalarTomcat
    instalarOPM
    instalarPIHole
}

function instalarPackDesarrolloWeb(){
    instalarApache
    instalarPHP
    instalarMariaDB
    instalarPHPMyAdmin
    instalarTomcat
}

function menuDeInstalaciones() {
    echo ""
    echo "Antes de instalar nada tenemos que actualizar los paquetes y el sistema"
    echo ""

    #El sleep para que el usuario le de tiempo a leerlo
    sleep 5 && sudo apt-get update && sudo apt-get upgrade -y

    while true; do

        echo ""

        echo "Seleccione una opción:"
        echo "1. Instalar Apache"
        echo "2. Instalar PHP"
        echo "3. Instalar PIhole (Solo debian)"
        echo "4. Instalar MariaDB"
        echo "5. Instalar PHPMyAdmin (se instalara tambien apache y PHP)"
        echo "6. Instalar Tomcat"
        echo "7. Instalar OpenMediaVault (Solo debian)"
        echo "8. Instalar pack desarrollo web (PHP,Apache,MariaDB y Tomcat)"
        echo "9. Instalar todo"
        echo "10. Menu principal"

        echo ""

        read -p "Ingrese el número de opción que desea ejecutar: " option

        case $option in
            1) instalarApache;;
            2) instalarPHP;;
            3) instalarPIHole;;
            4) instalarMariaDB;;
            5) instalarPHPMyAdmin;;
            6) instalarTomcat;;
            7) instalarOPM;;
            8) instalarPackDesarrolloWeb;;
            9) instalarTodo;;
            10) break;;
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
    #sudo su

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

#  -a Si existe
#  -d Existe directorio
#  -f Existe fichero
#  -r Tiene permisos de lectura
#  -w Tiene permisos de escritura
#  -x Tiene permisos de ejecución
#  -z Está vacía
#  ...

#  -eq  ==
#  -ne  !=
#  -lt  <
#  -gt  >
#  -le  <=
#  -ge  >=


#   Ordenes de sed

#   a   añade a las líneas seleccionadas una o más líneas más
#   c   reemplaza las líneas seleccionadas por un nuevo contenido
#   d   borra las líneas seleccionadas
#   g   copia el contenido del hold space al pattern space
#   G   añade el contenido del hold space al pattern space
#   h   copia el contenido del pattern space al hold space
#   H   añade el contenido del pattern space al hold space
#   i   inserta una o más líneas antes de las líneas seleccionadas
#   l   muestra todos los caracteres no imprimibles
#   n   cambia a la siguiente orden de la línea siguiente del comando
#   p   muestra las líneas seleccionadas
#   q   finaliza el comando SED de Linux
#   r   lee las líneas seleccionadas de un archivo
#   s   reemplaza una determinada cadena de caracteres por otra
#   x   intercambia el pattern space y el hold space entre sí
#   y   sustituye un determinado carácter por otro
#   w   escribe líneas en el archivo de texto
#   !   aplica el comando a las líneas que no coinciden con la entrada.
