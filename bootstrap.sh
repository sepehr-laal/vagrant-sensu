#!/bin/bash

echo "127.0.0.1 sensumaster.vagrant" >> /etc/hosts

if which puppet > /dev/null 2>&1; then
  echo 'Puppet Installed.'
else
  echo 'Installing Puppet Client.'
  wget http://apt.puppetlabs.com/puppetlabs-release-trusty.deb
  dpkg -i puppetlabs-release-trusty.deb
fi

apt-key update
apt-get update

# this is here because Puppet fails to instal rabbitmq-server
# it has something to do with not passing "--force-yes" to apt-get
apt-get -y --force-yes install rabbitmq-server
apt-get -y install puppet
apt-get -y install git
apt-get -y install ruby-dev

gem install --no-ri --no-rdoc r10k
cd /etc/puppet
rm -rf modules/

LIBRARIAN_FILE=$( cat << EOF
forge "http://forge.puppetlabs.com"

mod "arioch/redis"
mod "sensu/sensu"
mod "puppetlabs/stdlib"
mod "puppetlabs/apt"
mod "maestrodev/wget"
mod "garethr/erlang"
mod "puppetlabs/rabbitmq"
mod "nanliu/staging"
mod "yelp/uchiwa"

EOF
)

echo "${LIBRARIAN_FILE}" > /etc/puppet/Puppetfile
r10k puppetfile install -v

# warnings sux
sed -i '/^templatedir/d' /etc/puppet/puppet.conf

# generate sensu SSL certificates to the puppet manifest can use them
cd /root
wget http://sensuapp.org/docs/0.25/files/sensu_ssl_tool.tar
tar -xvf sensu_ssl_tool.tar
mv sensu_ssl_tool ssl_certs
cd ssl_certs
./ssl_certs.sh generate
