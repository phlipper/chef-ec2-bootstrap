#!/bin/bash

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

# update the base system
apt-get update
apt-get dist-upgrade -y


# check if we have /dev/sdb, unmount and reformat as xfs
if test -b /dev/sdb; then
  apt-get install xfsprogs
  grep '/dev/sdb' /etc/mtab && \
    umount `grep '/dev/sdb' /etc/mtab | cut -d ' ' -f 2`
  mkfs.xfs -fn size=64k /dev/sdb
fi


# install ruby 1.9
apt-add-repository ppa:brightbox/ruby-ng-experimental
apt-get update
apt-get install ruby1.9.3 ruby-switch


# rdoc, required for rvm later
gem install rdoc --no-rdoc --no-ri

# chef
gem install chef -v 0.10.8 --no-rdoc --no-ri



# setup the chef-solo paths
mkdir -p /var/chef/{config,cookbooks,log}

# write the chef-solo config file
curl -o /var/chef/config/chef-solo.rb $CHEF_SOLO_CONFIG_URL

echo '-------------------------'
echo '       Running Chef      '
echo '-------------------------'

# run chef-solo
chef-solo -c /var/chef/config/chef-solo.rb \
  -j $NODE_JSON_URL \
  -r $CHEF_COOKBOOKS_URL

# all done
exit 0
