provider aws {
  region = "eu-north-1"
  access_key =  "AKIA2OFNDSDIPX3KA74D"
  secret_key = "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"
}

resource "aws_instance" "my-first-server" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
}