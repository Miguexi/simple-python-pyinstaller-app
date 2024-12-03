pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Install dependencies') {
            steps {
                sh 'pip install --upgrade pip'
                sh 'pip install pyinstaller'
            }
        }
        stage('Build') {
            steps {
                sh 'pyinstaller --onefile hello.py'
            }
        }
        stage('Test') {
            steps {
                sh 'python -m unittest discover'
            }
        }
    }
}

