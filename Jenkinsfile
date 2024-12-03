pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                // Descarga el código desde el repositorio
                checkout scm
            }
        }
        stage('Install dependencies') {
            steps {
                // Actualiza pip e instala pyinstaller
                sh 'pip install --upgrade pip'
                sh 'pip install pyinstaller'
            }
        }
        stage('Build') {
            steps {
                // Asegura que calc.py esté accesible durante la compilación
                sh 'pyinstaller --onefile --paths=sources sources/add2vals.py'
            }
        }
        stage('Test') {
            steps {
                // Ejecuta las pruebas unitarias desde la carpeta sources
                dir('sources') {
                    sh 'python -m unittest test_calc.py'
                }
            }
        }
    }
}


