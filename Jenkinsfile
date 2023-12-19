def containerName="springbootdocker-bankproj"
def tag="latest"
def dockerHubUser="sharmilagaikwad29"
//def dockerHome= tool 'docker' 

node{
    
    stage("Git Clone")
    {
        git 'https://github.com/szalake/star-agile-banking-finance.git'
    }
    stage("maven build")
    {
        sh 'mvn clean package'
    }
    stage ("Archive .jar file")
    {archiveArtifacts artifacts: '**/*.jar', followSymlinks: false}
    stage ("check sock ")
    {
        sh 'sudo chmod 666 /var/run/docker.sock'
        //sh "sudo service jenkins restart"
        
    }
    
     stage('Image Build'){
        sh "docker build -t $containerName:$tag --pull --no-cache ."
        echo "Image build complete"
    }
    
    stage('Push to Docker Registry'){
        withCredentials([usernamePassword(credentialsId: 'dockerHubAccount', usernameVariable: 'dockerUser', passwordVariable: 'dockerPassword')]) {
            sh "docker login -u $dockerUser -p $dockerPassword"
            sh "docker tag $containerName:$tag $dockerUser/$containerName:$tag"
            sh "docker push $dockerUser/$containerName:$tag"
            echo "Image push complete"
        }
    }
}

