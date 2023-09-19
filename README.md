# terraform-p1-aws
1. My first Terraform project exploring IaC by setting up a basic AWS web server. Using resources; VPC, Internet Gateway, Route Table, Subnet, Route Table Association, Security Group, Security Group Ingress, Security Group Egress, Network Interface, Elastic IP, EC2, NACLs, NACL Association.

Reference video for this project: https://www.youtube.com/watch?v=SLB_c_ayRMo

2. Prior to running the script you also need to establish credentials access. I suggest setting up SSO with AWS Config.

I saved my steps in the file "aws_sso_setup_directions.md".

3. To start, run these terminal commands to initialize the repository and run the code.

    $ terraform init
    $ terraform plan
    $ terraform apply --auto-approve

4. I also included a diagram program that creates a picture of the terraform infrastructure, and saves to the file "graph.svg", using these commands to install and then create:

    $ sudo apt install graphviz
    $ terraform graph | dot -Tsvg > graph.svg

5. Don't forget to destroy.

    $ terraform destroy --auto-approve