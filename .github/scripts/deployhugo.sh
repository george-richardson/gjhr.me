set -ex

echo "Installing hugo"
curl -fSL "https://github.com/gohugoio/hugo/releases/download/v0.88.1/hugo_extended_0.88.1_Linux-64bit.tar.gz" -o hugo.tar.gz
mkdir -p /opt/hugo
tar -xf hugo.tar.gz -C /opt/hugo
sudo rm -f /usr/local/bin/hugo
sudo ln -s /opt/hugo/hugo /usr/local/bin/hugo
rm -f hugo.tar.gz

hugo version
which hugo

echo "Building and deploying website"
hugo
hugo deploy