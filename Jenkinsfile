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
                         }
                    }
            }

