# Case Study - Autoscaling Nextcloud on AWS

## main.tf 
This file contains the terraform code to create the infrastructure for the case study.


## variables.tf
This file contains the variables used in the main.tf file.
You can change the values of the variables in this file in your own .tfvars file to use your own AWS account.


## network.tf
This file contains the Terraform code for setting up the security groups. It includes the creation of security groups for the load balancer and EC2 instances, with rules for ingress and egress traffic.


## More Information
For more detailed information, please refer to the [Documentation](PCLS-HS23.pdf)