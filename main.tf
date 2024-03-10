provider "aws" {
    region = "us-east-1"
}

resource "aws_key_pair" "FlaskApp" {
    key_name = "Flask-app-key"
    public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_vpc" "terraformVpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "terraformSubnet" {
    vpc_id = aws_vpc.terraformVpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "terraGateway" {
    vpc_id = aws_vpc.terraformVpc.id
}

resource "aws_route_table" "terraRouteTable" {
    vpc_id = aws_vpc.terraformVpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.terraGateway.id
    } 
}

resource "aws_route_table_association" "terraRoute1" {
    subnet_id = aws_subnet.terraformSubnet.id
    route_table_id = aws_route_table.terraRouteTable.id
}

resource "aws_security_group" "terraSecGroup" {
    name = "terraSG"
    vpc_id = aws_vpc.terraformVpc.id

    ingress {
        description = "HTTP from VPC"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    }

    ingress {
        description = "SSH"
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "server" {
    ami = "ami-0261755bbcb8c4a84"
    instance_type = "t2.micro"
    key_name = aws_key_pair.FlaskApp.key_name
    vpc_security_group_ids = [aws_security_group.terraSecGroup.id]
    subnet_id = aws_subnet.terraformSubnet.id

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file ("~/.ssh/id_rsa")
      host = self.public_ip
    }

    provisioner "file" {
        source = "./app.py"
        destination = "/home/ubuntu/app.py"
    }

    provisioner "remote-exec" {
        inline = [
            "echo 'hello from the terraform script'",
            "sudo apt update -y",
            "sudo apt-get install -y python3-pip",
            "cd/home/ubuntu",
            "sudo pip install flask",
            "sudo python3 app.py &"
        ]  
    }
}