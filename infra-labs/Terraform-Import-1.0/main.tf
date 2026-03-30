resource "aws_instance" "name" {
 ami = "ami-0931307dcdc2a28c9"
    instance_type = "t3.micro"
    tags = {
        Name = "Terraform-Import-1.0"
    } 
}

resource "aws_s3_bucket" "name" {
    bucket = "prodprod-test3456f"
}