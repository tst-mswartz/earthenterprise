sudo wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo
sudo yum install -y epel-release ius-release
sudo yum install -y wget

sudo yum install -y ant bzip2 doxygen gcc-c++ patch python-argparse python27-lxml python27-setuptools \
  swig tar
sudo yum install -y devtoolset-2-gcc devtoolset-2-binutils devtoolset-2-toolchain devtoolset-2-gcc-gfortran
sudo yum install -y \
  bison-devel boost-devel cmake daemonize freeglut-devel \
  gdbm-devel geos-devel gettext giflib-devel GitPython \
  libcap-devel libmng-devel libpng-devel libX11-devel libXcursor-devel \
  libXft-devel libXinerama-devel libxml2-devel libXmu-devel libXrandr-devel \
  ogdi-devel openjpeg-devel openjpeg2-devel openssl-devel pcre pcre-devel \
  perl-Alien-Packages perl-Perl4-CoreLibs proj-devel python-devel python27-devel python-unittest2 \
  rpm-build rpmrebuild rsync scons shunit2 \
  xerces-c xerces-c-devel xorg-x11-server-devel yaml-cpp-devel zlib-devel
mkdir -p ~/opengee/rpm-build/
cd ~/opengee/rpm-build/
git clone https://github.com/thermopylae/gtest-devtoolset-rpm.git

cd gtest-devtoolset-rpm/
./bin/build.sh --use-docker=no
sudo yum install -y ./build/RPMS/x86_64/gtest-devtoolset2-1.8.0-1.x86_64.rpm
sudo yum install -y python27

