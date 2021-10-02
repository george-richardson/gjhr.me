set -ex

echo "Installing hugo"
curl -fSL "https://releases.hashicorp.com/terraform/0.11.15/terraform_0.11.15_linux_amd64.zip" -o hugo.tar.gz
tar -xf hugo.tar.gz -C /opt/hugo
sudo rm /usr/local/bin/hugo
sudo ln -s /opt/hugo/hugo /usr/local/bin/hugo
rm -f hugo.tar.gz

hugo version
which hugo

echo "Building and deploying website"
hugo deploy