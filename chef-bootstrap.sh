#!/bin/bash

# EXPORTS

echo '-------------------------'
echo '   Bootstrapping Chef    '
echo '-------------------------'

# run as root
if [ $(whoami) != "root" ]; then
  echo "You must be root to run the chef bootstrap setup"
  exit 2
fi

# is chef already bootstrapped?
command -v chef-solo >/dev/null && {
  echo "Chef is already bootstrapped"
  exit
}

# ensure a $NODE is specified
if [ -z "$NODE" ]; then
  echo "You must specify a NODE to provision"
  exit 2
fi

# ensure a $STACK is specified
if [ -z "$STACK" ]; then
  echo "You must specify a STACK to provision"
  exit 2
fi

# ensure an $ENV is set
if [ -z "$ENV" ]; then
  echo "You must specify a ENV to provision"
  exit 2
fi

# setup urls for chef data
export CHEF_BASE_URL="https://s3.amazonaws.com/chef.phlippers.net/$STACK"
export NODE_JSON_URL="$CHEF_BASE_URL/nodes/$NODE-$ENV.json"
export CHEF_COOKBOOKS_URL="$CHEF_BASE_URL/phlipper-cookbooks.tgz"
export CHEF_SOLO_CONFIG_URL="$CHEF_BASE_URL/chef-solo-config.rb"

# operate headless
export DEBIAN_FRONTEND=noninteractive

# ignore apparmor
echo "apparmor hold" | dpkg --set-selections

# update the system
apt-get update
apt-get dist-upgrade -y

# development and build tools
apt-get install -y build-essential

# we need curl to fetch rubygems
apt-get install -y curl

# ruby dependencies
apt-get install -y zlib1g-dev libssl-dev libreadline5-dev

# ruby
apt-get install -y ruby1.8 irb1.8 libopenssl-ruby1.8 libshadow-ruby1.8 ruby1.8-dev

# rubygems
curl -L 'http://production.cf.rubygems.org/rubygems/rubygems-1.8.17.tgz' | tar xvzf -
cd rubygems* && ruby1.8 setup.rb --no-ri --no-rdoc

# rdoc and rdoc-data, required for rvm later
gem1.8 install rdoc rdoc-data --no-rdoc --no-ri

# chef
gem1.8 install chef -v 0.10.8 --no-rdoc --no-ri

# symlink ruby and gem commands so chef can find them
ln -s /usr/bin/ruby1.8 /usr/bin/ruby
ln -s /usr/bin/gem1.8 /usr/bin/gem


# setup the chef-solo paths
mkdir -p /var/chef/{config,cookbooks,log}

# write the chef-solo config file
curl -o /var/chef/config/chef-solo.rb $CHEF_SOLO_CONFIG_URL

echo '-------------------------'
echo '       Running Chef      '
echo '-------------------------'

# run chef-solo
chef-solo -c /var/chef/config/chef-solo.rb -j $NODE_JSON_URL -r $CHEF_COOKBOOKS_URL

# all done
exit 0
