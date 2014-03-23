#!/bin/bash
#
#     install.sh
#
#     An install script for Fedora and OpenSUSE Systems.and Debian.
#
#     Copyright (c) 2014
#
#      Author:
#              Magdalen Berns
#     Contact:
#              <m.berns@thismagpie.com>

echo ""
echo "Install scripts available:"
echo ""
for i in * ; do
    echo "$i"
done;
# Check to see whether the installer is zypper.
# If so, then install necessary packages.
if [ -x /usr/bin/zypper ] ; then
    source ~/.profile
    echo ""
    echo "Going to install the following packages:"
    echo "gcc gcc-c++ curl and cpupower."
    echo "Login as root, now..."
    sudo zypper in -f gcc gcc gcc-c++ curl cpupower
    sudo cpupower frequency-set -g performance
    echo
    echo "Going to install the following packages:"
    echo "libatlas3 libatlas3-devel"
    sudo zypper in -f libatlas3 libatlas3-devel
fi

# Check to see whether the installer is yum.
# If so, then install necessary packages.
if [ -f /usr/bin/yum ] ; then
    source ~/.bashrc
    echo ""
    echo "Login as root, now..."
    sudo yum install gcc gcc gcc-c++ curl cpupower
    sudo cpupower frequency-set -g performance
    echo
    echo "Going to install the following packages:"
    echo "libatlas3 and libatlas3-devel."
    sudo yum install libatlas3 libatlas3-devel
fi

# Check to see whether the installer is yum.
# If so, then install necessary packages.
if [ -f /usr/bin/apt-get ] ; then
    echo ""
    source ~/.bash_profile
    echo "Login as root, now..."
    sudo apt-get install gcc gcc gcc-c++ curl cpupower
    sudo cpupower frequency-set -g performance
    echo
    echo "Going to install the following packages:"
    echo "libatlas3 and libatlas3-dev"
    sudo apt-get install libatlas3 libatlas3-dev
fi

#TODO put installer for apt-get
if [ -f /usr/include/atlas ] ; then
    echo "Setting CPLUS_INCLUDE_PATH..."
    CPLUS_INCLUDE_PATH=/usr/include/atlas
    echo "Setting C_INCLUDE_PATH..."
    C_INCLUDE_PATH=/usr/include/atlas
fi

echo "Going into bash login shell..."
echo "Downloading Ruby 2.1.1 "
\curl -sSL https://get.rvm.io | bash -s stable --ruby=2.1.1

if [ -x HOME/.rvm/bin ] ; then
    echo "rvm use ruby-2.1.1"
    source /home/magpie/.rvm/scripts/rvm
fi


# If gem has a Gemfile then it will be installed
if [ -f  Gemfile ] ; then
    echo "bundle install"
    bundle exec rake compile
    bundle exec rake spec
elif [ -f $PWD/extconf.rb ] ; then
    echo "Installing ..."
    ruby extconf.rb
fi

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source $HOME/.rvm/scripts/rvm

echo "                                                  "
echo "                                                  "
echo "                  +------------------------------+"
echo "                  |((((((((((((((()))))))))))))))|"
echo "                  +------------------------------+"
echo "                  |------------------------------|"
echo "                  |                              |"
echo "                  | Welcome, to the Login SHELL! |"
echo "                  | ~~~~~~~  ~~ ~~~ ~~~~~ ~~~~~~ |"
echo "                  +-------------+-#-+------------+"
echo "                  |______~_~*~~_{{_}}_~~*~_~_____|"
echo "                  +------------------------------+"
echo "                                                  "
echo "                                                  "
echo "                                                  "
echo "                                                  "
