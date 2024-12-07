
  
# **Terraform-SCV-Jenkins**

  

A xintinuación, se expondrá la realización de un despliegue de una aplicación Python mediante un pipeline de Jenkins.

  

---

# Índice

*  **Dockerfile**

*  **Aplicación Python (1-2)**

*  **Despligue en contenedor Docker (1-10)**

---

  

## **Dockerfile**

Para crear una imágen personalizada de jenkins, hemos seguido los pasos vistos en la asignatura:

  

```Dockerfile

FROM jenkins/jenkins # Imagen oficial de Jenkins disponible en Docker Hub.

USER root # Cambiamos al usuario root para ejecutar comandos en superusuario.

RUN apt-get update && apt-get install -y lsb-release # Actualizamos repositorios e instalamos lsb-release.

RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \

https://download.docker.com/linux/debian/gpg usr/share/keyrings/ # Descargamos la clave de docker y la guardamos en el directorio indicado.

RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \

https://download.docker.com/linux/debian/gpg # instalamos docker.

RUN echo "deb [arch=$(dpkg --print-architecture) \

signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \

https://download.docker.com/linux/debian \

$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

RUN apt-get update && apt-get install -y docker-ce-cli # Actualiza los repositorios e instala el cliente de Docker.

USER jenkins # Cambiamos de nuevo al usuario jenkins.

RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"

# instalamos plugins de jenkins llamados blueocean y docker-workflow enfocados a la integración continua y el despliegue de aplicaciones en contenedores(Docker).

  

```

---

## **Aplicación Python**

Tras ver el tutorial, lo hemos seguido tal y como se propone, obteniendo de esta manera, el Papeline siguiente, el cual se compone de tres fragmentos los cuales en el tutorial se muestran de uno en uno para así mostrar el funcionamiento del mismo:

  

```python

pipeline { # Definición de un pipeline

agent none # No se ejecuta en un agente específico

options {

skipStagesAfterUnstable() # Omitir etapas después de inestable

}

stages {

stage('Build') { # Etapas de construcción

agent {

docker {

image 'python:3.12.0-alpine3.18'  # Imagen de docker

}

}

steps {

sh 'python -m py_compile sources/add2vals.py sources/calc.py'

# Compilar archivos

stash(name: 'compiled-results', includes: 'sources/*.py*')

# Almacenar archivos compilados

}

}

```

---

## **Aplicación Python (1)**

  

```python

stage('Test') { # Etapas de pruebas

agent {

docker {

image 'qnib/pytest'  # Imagen de docker

}

}

steps {

sh 'py.test --junit-xml test-reports/results.xml sources/test_calc.py'

# Ejecutar pruebas unitarias y generar informe

}

post {

always {

junit 'test-reports/results.xml'

# Publica los informes de las pruebas unitarias

}

}

}

```

---

## **Aplicación Python (2)**

  

```python

stage('Deliver') { # Etapas de entrega

agent any  # Se ejecuta en cualquier agente

environment {

VOLUME = '$(pwd)/sources:/src'  # Volumen para montar el código fuente

IMAGE = 'cdrx/pyinstaller-linux:python2'  # Imagen de docker para empaquetar la app

}

steps {

dir(path: env.BUILD_ID) { # Directorio de trabajo

unstash(name: 'compiled-results') # Extraer archivos compilados

sh "docker run --rm -v ${VOLUME} ${IMAGE} 'pyinstaller -F add2vals.py'"

#Ejecuta PyInstaller dentro del contenedor Docker para generar un ejecutable independiente.

}

}

post { # Publica el artefacto

success { # Solo se hace si la etapa es exitosa

archiveArtifacts "${env.BUILD_ID}/sources/dist/add2vals"  #Archiva el ejecutable generado para su posterior acceso.

sh "docker run --rm -v ${VOLUME} ${IMAGE} 'rm -rf build dist'"

# Elimina los directorios de construcción y distribución generados durante el proceso, para limpiar el entorno.

}

}

}

}

}

  

```

---

## **Despligue en contenedor Docker**

Hemos creado el archivo Terraform, comenzando por la definicion del correcto despliegue del Docker:

```

terraform { # configurafión del proveedor de terraform y docker

required_providers {

docker = {

source = "kreuzwerker/docker"

version = "~> 3.0.1" # version del proveedor minima que debe de utilizar

}

}

}

  

# configura proveedor de docker para terraform interactue con docker

provider "docker" {}

```

---

## **Despligue (2)**

* Definimos la red Docker "jenkins-network". Posteriormente, usamos dos volúmenes los cuales se utilizan para la persistencia de datos entre contenedores.

```

resource "docker_network" "jenkins" {

name = "jenkins-network"

# proporciona un aislamiento de red para los contenedores relacionados con Jenkins

}

"jenkins-docker-certs" y "jenkins-data"

resource "docker_volume" "jenkins_certs" {

name = "jenkins-docker-certs"

}

resource "docker_volume" "jenkins_data" {

name = "jenkins-data"

}

```

---

## **Despligue (3)**

* Define un contenedor Docker llamado "jenkins-docker" que utiliza la imagen "docker:dind", el cual permite ejecutar Docker dentro de Docker (DinD)


```

resource "docker_container" "jenkins_docker" {

name = "jenkins-docker"

image = "docker:dind"

restart = "unless-stopped"

privileged = true

env = [

"DOCKER_TLS_CERTDIR=/certs"

]

```

---

## **Despligue (4)**

 - Aquí se define los puertos que se usan en el contenedor:

```

ports {

internal = 3000

external = 3000

}

ports {

internal = 5000

external = 5000

}

# Utilizado comunicación demonio docker (TLS)

ports {

internal = 2376

external = 2376

}

```

---

## **Despligue (5)**

* Definimos los volumenes del contenedor y la red que utilizará el mismo:

```

volumes {

volume_name = docker_volume.jenkins_certs.name

container_path = "/certs/client"

}

volumes {

volume_name = docker_volume.jenkins_data.name

container_path = "/var/jenkins_home"

}

networks_advanced {

name = docker_network.jenkins.name

aliases = [ "docker" ]

}

```

---

# **Despliegue (6)**

* Utilizamos la opción --storage-driver para configurar el controlador de almacenamiento. El Controlador overlay2 se utiliza para la gestión eficaz de capas y almacenamiento.

```

command = ["--storage-driver", "overlay2"]

}

```

---

## **Despligue (8)**

* Se crea un recurso de tipo 'docker_container' llamado 'jenkins-blueocean'

```

resource "docker_container" "jenkins_blueocean" {

name = "jenkins-blueocean"

image = "myjenkins-blueocean"

restart = "unless-stopped"

env = [

"DOCKER_HOST=tcp://docker:2376", # Dirección host docker

"DOCKER_CERT_PATH=/certs/client", # Ruta de certificados

"DOCKER_TLS_VERIFY=1", # Verificación TLS

]

```

---

## **Despligue (9)**

* Se definen los puertos que se expexpondrán en en el contenedor ara acceder a la interfaz web de Jenkins Blue Ocean desde el exterior. Así mismo, se utiliza para la comunicación de agentes Jenkins

```

ports {

internal = 8080

external = 8080

}

ports {

internal = 50000

external = 50000

}

```

---

## **Despligue (9)**

  

* Definimos los volúmenes que se montan en el contenedor y lo configuramos en modo solo lectura para proporcionar certificados necesarios.

```

volumes {

volume_name = docker_volume.jenkins_data.name

container_path = "/var/jenkins_home"

}

volumes {

volume_name = docker_volume.jenkins_certs.name

container_path = "/certs/client"

read_only = true

}

```

---

  

## **Despligue (10)**

  

* Conecta el contenedor a la red Docker llamada "jenkins", lo cual permite a comunicación entre contenedores en la misma red.


```

networks_advanced {

name = docker_network.jenkins.name

}

}

```