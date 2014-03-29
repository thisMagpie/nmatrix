#!/bin/bash
#
#     Linux-Installer.sh
#
#     An install script for Fedora and OpenSUSE Systems.and Debian.
#     Installs to home directory
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
    sudo zypper in -y gcc gcc gcc-c++ curl cpupower
    sudo cpupower frequency-set -g performance
    echo
    echo "Going to install the following packages:"
    echo "libatlas3 libatlas3-devel"
    sudo zypper in -y libatlas3 libatlas3-devel
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

echo "Installation for $s complete!"
echo "Setting PATHS"

if [ -f /usr/include/atlas ] ; then
    echo "Setting CPLUS_INCLUDE_PATH..."
    CPLUS_INCLUDE_PATH=/usr/include/atlas
    echo "Setting C_INCLUDE_PATH..."
    C_INCLUDE_PATH=/usr/include/atlas
fi

echo "Going into bash login shell..."
echo "Downloading Ruby 2.1.1 "
\curl -sSL https://get.rvm.io | bash -s stable --ruby=2.1.1 --auto-dotfiles

if [ -x $HOME/.rvm/bin ] ; then
    echo "rvm use ruby-2.1.1"
    source /home/magpie/.rvm/scripts/rvm
    if [ -d $HOME/.rvm/gems/ruby-2.1.1/gems ]; then
        cd $HOME/.rvm/gems/ruby-2.1.1/gems ;
        if [ ! -d $HOME/.rvm/gems/ruby-2.1.1/gems/narray ] ; then
            git clone https://github.com/SciRuby/narray.git
        fi
        if [ ! -d $HOME/.rvm/gems/ruby-2.1.1/gems/nmatrix ] ; then
            git clone https://github.com/SciRuby/nmatrix.git
        fi
    fi
fi

# If gem has a Gemfile then it will be installed
if [ -f  nmatrix/Gemfile ] ; then
    cd nmatrix
    echo "bundle install"
    bundle exec rake compile
    bundle exec rake spec
    cd ..
fi

if [ -f $PWD/narray/extconf.rb ] ; then
    echo "Installing ..."
    cd narray/
    ruby extconf.rb
    make
    make install
    cd ..
fi

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source $HOME/.rvm/scripts/rvm
pry -r 'nmatrix'
echo "                                                  "
echo "                                                  "
echo "                  +------------------------------+"
echo "                   ((((((((((((((())))))))))))))) "
echo "                  +------------------------------+"
echo "                   ------------------------------ "
echo "                                                  "
echo "                    Running Pry...."
echo "                    ~~~~~~~  ~~ ~~~ ~~~~~ ~~~~~~  "
echo "                  +-------------+-#-+------------+"
echo "                   ______~_~*~~_{{_}}_~~*~_~_____ "
echo "                  +------------------------------+"
echo "                                                  "
echo "                                                  "
