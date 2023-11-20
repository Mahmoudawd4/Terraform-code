resource "aws_instance" "bastion"{
  ami= var.AMIS[var.AWS_REGION]
#   ami = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion-allow-ssh.id]

  key_name = aws_key_pair.mykeypair.key_name
}

resource "aws_instance" "private"{
  ami = var.AMIS[var.AWS_REGION]
#   ami = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private-ssh.id]
  key_name = aws_key_pair.mykeypair.key_name
}
