pipeline{
            agent any
             tools{
                      maven 'maven3'
                  }
          
             stages{
                         stage("maven build")
                             {
                               steps{
                                sh "mvn clean package"
                              }
                               post{
                                       success{
                                                     echo "archieving the artifacts"
                                                      archiveArtifacts artifacts: '**/target/*.war'
                                       }
                               }
                             }           
                                         
                          stage("deploy to tomcat server")
                          {
                              deploy adapters: [tomcat9(credentialsId: 'tomcat', path: '', url: 'http://3.111.37.17:8080/manager/html')], contextPath: 'http://3.111.37.17:8080/manager/html', war: '**/*.war'        
                         }
                    }
            }

