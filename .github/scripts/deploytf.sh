set -ex

echo "Installing terraform"
curl -fSL "https://releases.hashicorp.com/terraform/0.11.15/terraform_0.11.15_linux_amd64.zip" -o terraform.zip
sudo unzip terraform.zip -d /opt/terraform
sudo rm /usr/local/bin/terraform
sudo ln -s /opt/terraform/terraform /usr/local/bin/terraform
rm -f terraform.zip

terraform -version
which terraform

echo "Executing terraform"
terraform init -input=false
terraform apply -auto-approve