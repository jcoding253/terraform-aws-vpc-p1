# terraform-p1-aws
#1 My first Terraform project exploring IaC by setting up a basic AWS web server. Using resources; VPC, Internet Gateway, Route Table, Subnet, Route Table Association, Security Group, Security Group Ingress, Security Group Egress, Network Interface, Elastic IP, EC2, NACLs, NACL Association. Reference video for this project: https://www.youtube.com/watch?v=SLB_c_ayRMo

#Personal Challenges: I tried using separate aws_vpc_security_group_ingress_rule (and egress) for the aws_security_group as opposed to the inline rules that are currently being used in the code (as suggested by the documentation to avoid bugs with "tags" and "descriptions") but I was unable to make it work. And I wasn't able to find good documentation on it. So I had to stick with the old inline approach. 

#Continued: I also, tried using NACL's which worked when I added them after I "terraform apply" the original code, added them to the code, saved and applied again. But if I tried to put them in the code from the start and then applied, it would be bugged. I never figured out why but it was out of the scope of the project so I just left them out for now.

#Future goals: In this project, I learned how to use repo branches to manage 3 versions of my project. For my next project, these are my goals: 

    -create modulated environments for prod and dev
    -explore the use of workspaces, variables.tf and auto.tfvars
    -create a directory for examples and testing
    -use the "Terraform Modules Directory" to put together my project rather than writing the code from scratch, 
     documentation, and video resources like I have in the past. This will be much more efficient and versatile.

#2 To start, prior to running the script you also need to establish credentials access. I suggest setting up SSO with AWS Config. I saved my steps in the file "aws_sso_setup_directions.md". I also had to go into the AWS EC2 console and generate a key-pair .pem file, which I saved in the ~/.ssh directory on my local machine. I named it "web-key", which needs to match the main.tf code under "aws_instance".

#3 Next, run these terminal commands to initialize the repository and run the code.

    terraform init
    terraform plan
    terraform apply --auto-approve

#4 After launching I did need to open the firewall ports to allow the public ip for the web server which can be found by clicking on the EC2 instance in the "AWS EC2 Console". On Kubuntu I ran these commands to install and open the gui:

    sudo apt-get install gufw
    sudo gufw

Then I enabled the firewall switch button on the top left, went to rules in the middle, and added a new advanced rule that allowed "both" directions, "only tcp", "from" the public "ip" of the EC2 instance, and allowed "ports 22,80,443". 

#5 Finally, to open the website click the url "public ip address" link from the EC2 instance. There are no ssl certificates in this basic code, so in the address bar you will need to double click the url and delete the "s" on the defaulted https, so it only runs in http. 

#6 Bonus: I also included a diagram program that creates a picture of the terraform infrastructure, and saves to the file "graph.svg", using these commands to install and then create:

    sudo apt install graphviz
    terraform graph | dot -Tsvg > graph.svg

#7 Don't forget to destroy.

    terraform destroy --auto-approve
