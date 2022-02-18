#!/bin/bash

########################################################################
# Copyright 1998-2020 CERN for the benefit of the EvtGen authors       #
#                                                                      #
# This file is part of EvtGen.                                         #
#                                                                      #
# EvtGen is free software: you can redistribute it and/or modify       #
# it under the terms of the GNU General Public License as published by #
# the Free Software Foundation, either version 3 of the License, or    #
# (at your option) any later version.                                  #
#                                                                      #
# EvtGen is distributed in the hope that it will be useful,            #
# but WITHOUT ANY WARRANTY; without even the implied warranty of       #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
# GNU General Public License for more details.                         #
#                                                                      #
# You should have received a copy of the GNU General Public License    #
# along with EvtGen.  If not, see <https://www.gnu.org/licenses/>.     #
########################################################################

# This script installs EvtGen with all external dependencies.
# The variable INSTALL_PREFIX specifies the installation location.
# The variable VERSION specifies the tag of EvtGen you want to use.
# The list of available tags can be found by either going to the url
# https://phab.hepforge.org/source/evtgen/tags/master
# or issuing the command (without the need to clone the git repository)
# git ls-remote --tags http://phab.hepforge.org/source/evtgen.git | cut -d '/' -f3
# The recommended versions of the external dependencies are given below.
# Later versions should be OK as well, assuming their C++ interfaces do not change.
# HepMC (either HepMC2 or HepMC3, the latter is recommended) is mandatory.
# Note that some earlier EvtGen versions will not be compatible with all
# external dependency versions given below, owing to C++ interface differences;
# see the specific tagged version of the EvtGen/README file for guidance.
# It is also not possible to compile Tauola++ on macOS at present, unless you
# are building on a volume with a case sensitive file system, so this is
# disabled by default.
# To obtain this script use the "Download File" option on the right of the webpage:
# https://phab.hepforge.org/source/evtgen/browse/master/setupEvtGen.sh?view=raw

# Location in which to install
INSTALL_PREFIX="/home/py8_evtgen_HepMC"
mkdir $INSTALL_PREFIX

# EvtGen version or tag number (or branch name). No extra spaces on this line!
VERSION=R02-01-01

# HepMC version numbers - change HEPMCMAJORVERSION to 2 in order to use HepMC2
HEPMCMAJORVERSION="3"
HEPMC2VER="2.06.10"
HEPMC3VER="3.2.0"
HEPMC2PKG="HepMC-"$HEPMC2VER
HEPMC3PKG="HepMC3-"$HEPMC3VER
HEPMC2TAR="hepmc"$HEPMC2VER".tgz"
HEPMC3TAR=$HEPMC3PKG".tar.gz"

# Pythia version number with no decimal points, e.g. 8230 corresponds to version 8.230. This
# follows the naming convention of Pythia install tar files. Again, no extra spaces allowed.
PYTHIAVER=8306
PYTHIAPKG="pythia"$PYTHIAVER
PYTHIATAR=$PYTHIAPKG".tgz"

# Determine OS
osArch=`uname`

#This is for systems with cmake and cmake3
if command -v cmake3; then
    CMAKE=cmake3
else
    CMAKE=cmake
fi

echo Will install EvtGen version $VERSION and its dependencies in $INSTALL_PREFIX

BUILD_BASE=$INSTALL_PREFIX/build
mkdir $BUILD_BASE

echo Temporary build area is $BUILD_BASE

cd $BUILD_BASE

mkdir -p tarfiles
mkdir -p sources
mkdir -p builds

echo Downloading EvtGen source from GIT

cd sources
git clone https://phab.hepforge.org/source/evtgen.git evtgen
cd evtgen
git checkout $VERSION

echo Downloading sources of external dependencies

cd $BUILD_BASE/tarfiles

if [ "$osArch" == "Darwin" ]
then
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
fi

if [ "$HEPMCMAJORVERSION" -lt "3" ]
then
    curl -O http://hepmc.web.cern.ch/hepmc/releases/$HEPMC2TAR
else
    curl -O http://hepmc.web.cern.ch/hepmc/releases/$HEPMC3TAR
fi
curl -O https://pythia.org/download/pythia83/$PYTHIATAR

cd $BUILD_BASE/sources

echo Extracting external dependencies
if [ "$HEPMCMAJORVERSION" -lt "3" ]
then
    tar -xzf $BUILD_BASE/tarfiles/$HEPMC2TAR
else
    tar -xzf $BUILD_BASE/tarfiles/$HEPMC3TAR
fi
tar -xzf $BUILD_BASE/tarfiles/$PYTHIATAR

cd $BUILD_BASE

if [ "$HEPMCMAJORVERSION" -lt "3" ]
then
    echo Installing HepMC from $BUILD_BASE/sources/$HEPMC2PKG
    mkdir -p $BUILD_BASE/builds/HepMC2
    cd $BUILD_BASE/builds/HepMC2
    $CMAKE -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_PREFIX $BUILD_BASE/sources/$HEPMC2PKG -Dmomentum:STRING=GEV -Dlength:STRING=MM
    make
    make install

    echo Installing pythia8 from $BUILD_BASE/sources/$PYTHIAPKG
    cd $BUILD_BASE/sources/$PYTHIAPKG
    ./configure --enable-shared --prefix=$INSTALL_PREFIX
    make
    make install

else

    echo Installing HepMC3 from $BUILD_BASE/sources/$HEPMC3PKG
    mkdir -p $BUILD_BASE/builds/HepMC3
    cd $BUILD_BASE/builds/HepMC3
    $CMAKE -DHEPMC3_ENABLE_ROOTIO:BOOL=OFF -DHEPMC3_ENABLE_PYTHON:BOOL=OFF -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_PREFIX $BUILD_BASE/sources/$HEPMC3PKG
    make
    make install

    echo Installing pythia8 from $BUILD_BASE/souces/$PYTHIAPKG
    cd $BUILD_BASE/sources/$PYTHIAPKG
    ./configure --enable-shared --prefix=$INSTALL_PREFIX
    make
    make install
fi

echo Installing EvtGen from $BUILD_BASE/sources/evtgen
mkdir -p $BUILD_BASE/builds/evtgen
cd $BUILD_BASE/builds/evtgen
if [ "$osArch" == "Darwin" ]
then
    if [ "$HEPMCMAJORVERSION" -lt "3" ]
    then
        $CMAKE -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_PREFIX $BUILD_BASE/sources/evtgen \
		-DEVTGEN_HEPMC3:BOOL=OFF -DHEPMC2_ROOT_DIR:PATH=$INSTALL_PREFIX \
		-DEVTGEN_PYTHIA:BOOL=ON  -DPYTHIA8_ROOT_DIR:PATH=$INSTALL_PREFIX 
    else
        $CMAKE -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_PREFIX $BUILD_BASE/sources/evtgen \
		-DEVTGEN_HEPMC3:BOOL=ON  -DHEPMC3_ROOT_DIR:PATH=$INSTALL_PREFIX \
		-DEVTGEN_PYTHIA:BOOL=ON  -DPYTHIA8_ROOT_DIR:PATH=$INSTALL_PREFIX 
    fi
else
    if [ "$HEPMCMAJORVERSION" -lt "3" ]
    then
        $CMAKE -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_PREFIX $BUILD_BASE/sources/evtgen \
		-DEVTGEN_HEPMC3:BOOL=OFF -DHEPMC2_ROOT_DIR:PATH=$INSTALL_PREFIX \
		-DEVTGEN_PYTHIA:BOOL=ON  -DPYTHIA8_ROOT_DIR:PATH=$INSTALL_PREFIX 
    else
        $CMAKE -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_PREFIX $BUILD_BASE/sources/evtgen \
		-DEVTGEN_HEPMC3:BOOL=ON  -DHEPMC3_ROOT_DIR:PATH=$INSTALL_PREFIX \
		-DEVTGEN_PYTHIA:BOOL=ON  -DPYTHIA8_ROOT_DIR:PATH=$INSTALL_PREFIX
    fi
fi
make
make install

echo Setup done.
echo To complete, set the Pythia8 data path:
if [ "$PYTHIAVER" -lt "8200" ]
then
    echo PYTHIA8DATA=$INSTALL_PREFIX/xmldoc
else
    echo PYTHIA8DATA=$INSTALL_PREFIX/share/Pythia8/xmldoc
fi

echo If installation fully successful you can remove the temporary build area $BUILD_BASE
cd $BUILD_BASE
