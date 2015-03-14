#!/bin/bash

# mpwget fichero_recursos servidor1 servidor2

# Comprobación argumentos correctos
if [ $# -lt 3 ] 
	then
	echo "Uso: $0 <fichero_recursos> <servidor1> <servidor2> ... "
	exit 1
fi

# Leer recursos a pedir
FICHRECURSOS=`cat $1`
POS=0
for linea in $FICHRECURSOS; do
	RECURSOS[$(($POS))]=$linea
	POS=$(($POS+1))
done

# Crear lista de los servidores
N_SERV=$(($#-1)) # Numero de servidores a los que realizar peticiones
echo "El numero de servidores es: <$N_SERV>"

POS=1
for arg in $*; do
	if [ $POS -gt 1 ] &&  [ $POS -le $# ] 
		then
		SERVIDORES[$(($POS-1))]=$arg
	fi
	POS=$(($POS+1))
done

# Comprobar que el servidor es accesible
# Codigo basado en la solución de stackoverflow: http://stackoverflow.com/questions/18258364/ping-tool-to-check-if-server-is-online
CHECKED=0
I=1
while [ $CHECKED -eq 0 ] && [ $I -le $N_SERV ] # Buscar un servidor accesible
do
	ping -c 1 ${SERVIDORES[@]:$I:1} > /dev/null 2>&1
	if [ $? -ne 0 ] ; then
		echo "Servidor ${SERVIDORES[@]:$I:1} no alcanzable"
	else
		CHECKED=1
		SERV_REQ=${SERVIDORES[@]:$I:1}
	fi
	if [ $CHECKED -eq 0 ] && [ $I -eq $N_SERV ] ; then # Si no hay servidores accesibles
		echo "Los servidores indicados no estan disponibles"
		exit 2
	fi
	I=$(($I+1))
done

echo "El servidor donde se pide el tamaño de los recursos es: <$SERV_REQ>"

# Averiguar tamaño de los recursos
# Content-Length: 
N=0
for recurso in ${RECURSOS[*]}; do
	# Parsear la cabezera Content-Length
	# http://stackoverflow.com/questions/24943170/how-to-parse-http-headers-using-bash
	INPUT=$(curl --silent --head http://$SERV_REQ/$recurso | grep Content-Length: | awk {'print $2'} | sed -e 's/\r*$//')
	CONTENTLENGTH[$(($N))]=$INPUT
	echo "Tamaño del recurso $((N+1)) (Bytes): <${CONTENTLENGTH[$(($N))]}>"
	N=$(($N+1))
done

# pedir a cada servidor un fragmento de cada recurso

# Determinar limites de cada fragmento de los recursos
# Frag = Tamaño/NSERV
# 13%5 = 3
#

I=0
for server in ${SERVIDORES[*]}; do
	NREC=0
	for recurso in ${RECURSOS[*]}; do
		length=${CONTENTLENGTH[$(($NREC))]}
		# echo "El valor de length es: <$length>"
		FRAG=$(($length/$N_SERV)) # Tamaño del fragmento, segun el número de servidores
		# echo "El valor del fragmento es: <$FRAG>"
		if [ $I -eq 0 ] # Si es el primer fragmento de recurso
			then
			# echo "Haciendo peticion bytes=$(($FRAG*$I+1))-$(($FRAG*$(($I+1))))"
			# curl GET --silent -H "range: bytes=$(($FRAG*$I+1))-$(($FRAG*$(($I+1))))" http://$server/$recurso > ${recurso##*/} && echo ">>>>>>>>>>>>< Creando fichero ${recurso##*/}"
			# http://stackoverflow.com/questions/2664740/extract-file-basename-without-path-and-extension-in-bash
			echo "Haciendo peticion bytes=1-$(($FRAG))"
			curl GET --silent -H "range: bytes=1-$(($FRAG))" http://$server/$recurso > ${recurso##*/} && echo ">>>>>>>>>>>>< Creando fichero ${recurso##*/}"
		else
			echo "Haciendo peticion bytes=$(($FRAG*$I+1))-$(($FRAG*$(($I+1))))"
			curl GET --silent -H "range: bytes=$(($FRAG*$I+1))-$(($FRAG*$(($I+1))))" http://$server/$recurso >> ${recurso##*/} && echo ">>>>>>>>>>>>< Modificando fichero ${recurso##*/}"
		fi
		NREC=$(($NREC+1))
	done
	I=$(($I+1))
done

# for server in ${SERVIDORES[*]}; do
# 	echo $server
# done

# ~coes/index.html
# informacion.html
# ~ssoo/SD/reto_http_14b.html