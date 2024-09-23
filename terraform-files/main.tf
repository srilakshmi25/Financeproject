resource "aws_instance" "test-server" {
  ami           = "ami-0e86e20dae9224db8"  # Replace with your AMI
  instance_type = "t2.micro"
  key_name      = "ansiblef"
  vpc_security_group_ids = ["sg-078c941ec791c7003"]

  tags = {
    Name = "test-server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./ansiblef.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'wait to start the instance'"
    ]
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > inventory"
  }

  provisioner "local-exec" {
    command = "ansible-playbook /var/lib/jenkins/workspace/Care-Health/terraform-files/ansibleplaybook.yml"
  }
}

