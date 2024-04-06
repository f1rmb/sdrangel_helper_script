#!/usr/bin/env bash
#
# Copyright (C) 2023-2024 F1RMB; Daniel Caujolle-Bert <f1rmb.daniel@naboo-homelinux.org>
#               2019-2023 F4EXB; Edouard Griffiths <f4exb06@gmail.com> and contributors to the "Compile from source in Linux" wiki page
#
# License GPLv2: GNU GPL version 2 <http://gnu.org/licenses/gpl2.html>.


# Where sources will be downloaded
SRC_ROOT=~/src/Ham/SDRangel/sources

# Installation destination (binaries)
INSTALL_DIR=/opt/sdrangel
# Installation destination (dependencies)
DEPS_INSTALL_DIR=$INSTALL_DIR/deps
SOAPY_MODULE_VERSION="modules0.8-2"

# Internal variables
SCRIPT_VERSION="0.4.2"
SANITY_RUN_ONCE=1

OPTION_EXECUTE_FROM_SCRATCH=0
OPTION_ENABLE_SOAPY=0
OPTION_ENABLE_SHUTTERPRO=0

SHUTTLEPRO_BINARY=/usr/local/bin/shuttlepro
SHUTTLEPRO_DEVICE=/dev/input/by-id/usb-Contour_Design_ShuttleXpress-event-if00

# Silence "Couldn't connect to accessibility bus: Failed to connect to socket..." error message
export NO_AT_BRIDGE=1


## override variables
if [ -e ~/.sdrangel_helper_options.txt ]; then
    echo "Read options from ~/.sdrangel_helper_options.txt"
    source ~/.sdrangel_helper_options.txt
fi


echo "SDRangel helper script v$SCRIPT_VERSION"


function SanityCheck() {
    ## Just to trigger sudo
    if [ x$SANITY_RUN_ONCE = "x1" ]; then
	sudo true
    fi
    
    if [ ! -d $DEPS_INSTALL_DIR ]; then
	sudo mkdir -p $DEPS_INSTALL_DIR
	sudo chown $USER:users $DEPS_INSTALL_DIR
    fi

    if [ x$SANITY_RUN_ONCE = "x1" ]; then
	sudo apt-get update && sudo apt-get -y install \
				    git cmake g++ pkg-config autoconf automake libtool libfftw3-dev libusb-1.0-0-dev libusb-dev libhidapi-dev libopengl-dev \
				    qtbase5-dev qtchooser libqt5multimedia5-plugins qtmultimedia5-dev libqt5websockets5-dev \
				    qttools5-dev qttools5-dev-tools libqt5opengl5-dev libqt5quick5 libqt5charts5-dev \
				    qml-module-qtlocation  qml-module-qtpositioning qml-module-qtquick-window2 \
				    qml-module-qtquick-dialogs qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts \
				    libqt5serialport5-dev qtdeclarative5-dev qtpositioning5-dev qtlocation5-dev libqt5texttospeech5-dev \
				    qtwebengine5-dev qtbase5-private-dev \
				    libfaad-dev zlib1g-dev libboost-all-dev libasound2-dev pulseaudio libopencv-dev libxml2-dev bison flex \
				    ffmpeg libavcodec-dev libavformat-dev libopus-dev doxygen graphviz
	export SANITY_RUN_ONCE=0
    fi
}

##
### aptdec
###
function aptdec() {
    cd $SRC_ROOT

    if [ ! -d aptdec ]; then
	sudo apt-get -y install libsndfile-dev
	git clone https://github.com/srcejon/aptdec.git
	cd aptdec
	git checkout libaptdec
	git submodule update --init --recursive
    else
	cd aptdec
	git pull
    fi

    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/aptdec ..
    make -j $(nproc) || exit 2
    make install
}

##
### CM265cc
##
function CM265cc() {
    cd $SRC_ROOT

    if [ ! -d cm256cc ]; then
	git clone https://github.com/f4exb/cm256cc.git
	cd cm256cc
    else
	cd cm256cc
	git pull
    fi
    
    git reset --hard 6f4a51802f5f302577d6d270a9fc0cb7a1ee28ef
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/cm256cc ..
    make -j $(nproc) || exit 2
    make install
}


##
### LibDAB
##
function LibDAB() {
    cd $SRC_ROOT

    if [ ! -d dab-cmdline ]; then
	git clone https://github.com/srcejon/dab-cmdline
	cd dab-cmdline/library
    else
	cd dab-cmdline/library
	git pull
    fi

    git checkout msvc
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/libdab ..
    make -j $(nproc) || exit 2
    make install
}

##
### MBElib
##
function MBElib() {
    cd $SRC_ROOT

    if [ ! -d mbelib ]; then
	git clone https://github.com/szechyjs/mbelib.git
	cd mbelib
    else
	cd mbelib
	git pull
    fi
	
    git reset --hard 9a04ed5c78176a9965f3d43f7aa1b1f5330e771f
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/mbelib ..
    make -j $(nproc) || exit 2
    make install
}

##
### SerialDV
##
function SerialDV() {
    cd $SRC_ROOT
    
    if [ ! -d serialDV ]; then
	git clone https://github.com/f4exb/serialDV.git
	cd serialDV
    else
	cd serialDV
	git pull
    fi
    
    git reset --hard "v1.1.4"
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/serialdv ..
    make -j $(nproc) || exit 2
    make install
}

##
### DSDcc
##
function DSDcc() {
    cd $SRC_ROOT
    
    if [ ! -d dsdcc ]; then
	git clone https://github.com/f4exb/dsdcc.git
	cd dsdcc
    else
	cd dsdcc
	git pull
    fi

    git reset --hard "v1.9.5"
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/dsdcc -DUSE_MBELIB=ON -DLIBMBE_INCLUDE_DIR=$DEPS_INSTALL_DIR/mbelib/include -DLIBMBE_LIBRARY=$DEPS_INSTALL_DIR/mbelib/lib/libmbe.so -DLIBSERIALDV_INCLUDE_DIR=$DEPS_INSTALL_DIR/serialdv/include/serialdv -DLIBSERIALDV_LIBRARY=$DEPS_INSTALL_DIR/serialdv/lib/libserialdv.so ..
    make -j $(nproc) || exit 2
    make install
}

##
### Codec2/FreeDV
##
function Codec2_FreeDV() {
    cd $SRC_ROOT
    
    if [ ! -d codec2 ]; then
	sudo apt-get -y install libspeexdsp-dev libsamplerate0-dev
	git clone https://github.com/drowe67/codec2.git
	cd codec2
    else
	cd codec2
	git pull
    fi
    
    #git reset --hard 76a20416d715ee06f8b36a9953506876689a3bd2
    git reset --hard "v1.0.3"
    
    rm -rf mkdir build_linux; mkdir build_linux; cd build_linux
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/codec2 ..
    make -j $(nproc) || exit 2
    make install
}

##
### SGP4
##
function SGP4() {
    cd $SRC_ROOT
    
    if [ ! -d sgp4 ]; then
	git clone https://github.com/dnwrnr/sgp4.git
	cd sgp4
    else
	cd sgp4
	git pull
    fi
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/sgp4 ..
    make -j $(nproc) || exit 2
    make install
}

##
### LibSigMF
##
function LibSigMF() {
    cd $SRC_ROOT
    
    if [ ! -d libsigmf ]; then
	git clone https://github.com/f4exb/libsigmf.git
	cd libsigmf
    else
	cd libsigmf
	git pull
    fi
    
    git checkout "new-namespaces"
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/libsigmf .. 
    make -j $(nproc) || exit 2
    make install
}

############################
##### HARDWARE DEVICES #####
############################

##
### Airspy
##
function Airspy_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d libairspy ]; then
	git clone https://github.com/airspy/airspyone_host.git libairspy
	cd libairspy
    else
	cd libairspy
	git pull
    fi
    
    git reset --hard 37c768ce9997b32e7328eb48972a7fda0a1f8554
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/libairspy ..
    make -j $(nproc) || exit 2
    make install
}

##
### SDRplay RSP1
##
function SDRplay_RSP1_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d libmirisdr-4 ]; then
	git clone https://github.com/f4exb/libmirisdr-4.git
	cd libmirisdr-4
    else
	cd libmirisdr-4
	git pull
    fi
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/libmirisdr ..
    make -j $(nproc) || exit 2
    make install
}

##
### RTL-SDR
##
function RTL_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d librtlsdr ]; then
	git clone https://github.com/osmocom/rtl-sdr.git librtlsdr
	cd librtlsdr
    else
	cd librtlsdr
	git pull
    fi
    
    git reset --hard 420086af84d7eaaf98ff948cd11fea2cae71734a
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DDETACH_KERNEL_DRIVER=ON -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/librtlsdr ..
    make -j $(nproc) || exit 2
    make install
}

##
### Pluto SDR
##
function Pluto_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d libiio ]; then
	git clone https://github.com/analogdevicesinc/libiio.git
	cd libiio
    else
	cd libiio
	git pull
    fi
    
    git reset --hard v0.21
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/libiio -DINSTALL_UDEV_RULE=OFF ..
    make -j $(nproc) || exit 2
    make install
}

##
### BladeRF all versions
##
function BladeRF_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d bladeRF ]; then
	git clone https://github.com/Nuand/bladeRF.git
	cd bladeRF/host
    else
	cd bladeRF/host
	git pull
    fi
    
    git reset --hard "2023.02"
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/libbladeRF -DINSTALL_UDEV_RULES=OFF ..
    make -j $(nproc) || exit 2
    make install
}

##
### HackRF
##
function HackRF_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d hackrf ]; then
	git clone https://github.com/greatscottgadgets/hackrf.git
	cd hackrf/host
    else
	cd hackrf/host
	git pull
    fi
    
    git reset --hard "v2022.09.1"
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/libhackrf -DINSTALL_UDEV_RULES=OFF ..
    make -j $(nproc) || exit 2
    make install
}

##
### LimeSDR
##
function LimeSDR_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d LimeSuite ]; then
	git clone https://github.com/myriadrf/LimeSuite.git
	cd LimeSuite
    else
	cd LimeSuite
	git pull
    fi
    
    #git reset --hard HEAD; git pull
    git reset --hard "v20.01.0"
    
    rm -rf builddir; mkdir builddir; cd builddir
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/LimeSuite -DCMAKE_PREFIX_PATH=$DEPS_INSTALL_DIR/SoapySDR -DCMAKE_MODULE_PATH=$DEPS_INSTALL_DIR/SoapySDR/share/cmake ..
    make -j $(nproc) || exit 2
    make install
}

##
### AirspyHF
##
function AirspyHF_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d airspyhf ]; then
	git clone https://github.com/airspy/airspyhf
	cd airspyhf
    else
	cd airspyhf
	git pull
    fi
    
    git reset --hard 1af81c0ca18944b8c9897c3c98dc0a991815b686
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/libairspyhf ..
    make -j $(nproc) || exit 2
    make install
}

##
### Perseus
##
function Perseus_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d libperseus-sdr ]; then
	git clone https://github.com/f4exb/libperseus-sdr.git
	cd libperseus-sdr
    else
	cd libperseus-sdr
	git pull
    fi
	
    git checkout fixes
    git reset --hard afefa23e3140ac79d845acb68cf0beeb86d09028
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/libperseus ..
    make -j $(nproc) || exit 2
    make install
}

##
### USRP
##
function USRP_SDR() {
    cd $SRC_ROOT

    export postinstallUSRP=0
    
    if [ ! -d uhd ]; then
	sudo apt-get -y install libboost-all-dev libusb-1.0-0-dev python3-mako doxygen python3-docutils cmake build-essential
	git clone https://github.com/EttusResearch/uhd.git
	cd uhd/host
	export postinstallUSRP=1
    else
	cd uhd/host
	git pull
    fi
    
    git reset --hard v4.5.0.0

    rm -rf build; mkdir build; cd build
    cmake -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/uhd -DENABLE_TESTS=OFF ../
    make -j $(nproc) || exit 2
    make install
    $DEPS_INSTALL_DIR/uhd/lib/uhd/utils/uhd_images_downloader.py

    if [ x$postinstallUSRP = "x1" ]; then
        # The following aren't required if installed to /
	echo $DEPS_INSTALL_DIR/uhd/lib | sudo dd of=/etc/ld.so.conf.d/uhd.conf
	sudo ldconfig
	export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$DEPS_INSTALL_DIR/uhd/lib/pkgconfig
	# Enable USB access from user accounts
	cd $DEPS_INSTALL_DIR/uhd/lib/uhd/utils
	sudo cp uhd-usrp.rules /etc/udev/rules.d/
	sudo udevadm control --reload-rules
	sudo udevadm trigger
    fi
}

##
### XTRX
##
function XTRX_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d xtrx-images ]; then
	sudo apt-get -y install build-essential dkms python3 python3-cheetah
	git clone https://github.com/f4exb/images.git xtrx-images
	cd xtrx-images
	git submodule init
	git submodule update
	cd sources
    else
	cd xtrx-images
	git pull
	cd sources
    fi
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/xtrx-images -DENABLE_SOAPY=NO ..
    make -j $(nproc) || exit 2
    make install
}


##################
##### Soapy ######
##################

##
### Soapy SDR
##
function Soapy_SDR_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d SoapySDR ]; then
	git clone https://github.com/pothosware/SoapySDR.git
	cd SoapySDR
    else
	cd SoapySDR
	git pull
    fi

    ##git reset --hard "soapy-sdr-0.7.1"
    git reset --hard HEAD; git pull
    
    rm -rf build; mkdir build; cd build
    cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/SoapySDR  ..
    make -j $(nproc) || exit 2
    make install
}

##
### Soapy RTL-SDR
##
function Soapy_RTL_SDR_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d SoapyRTLSDR ]; then
	git clone https://github.com/pothosware/SoapyRTLSDR.git
	cd SoapyRTLSDR
    else
	cd SoapyRTLSDR
	git pull
    fi
	
    rm -rf build; mkdir build; cd build
    cmake -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/SoapySDR -DCMAKE_MODULE_PATH=$DEPS_INSTALL_DIR/SoapySDR/share/cmake -DRTLSDR_INCLUDE_DIR=$DEPS_INSTALL_DIR/librtlsdr/include -DRTLSDR_LIBRARY=$DEPS_INSTALL_DIR/librtlsdr/lib/librtlsdr.so -DSOAPY_SDR_INCLUDE_DIR=$DEPS_INSTALL_DIR/SoapySDR/include -DSOAPY_SDR_LIBRARY=$DEPS_INSTALL_DIR/SoapySDR/lib/libSoapySDR.so ..
    make -j $(nproc) || exit 2
    make install
}

##
### Soapy HackRF
##
function Soapy_HackRF_SDR() {
    cd $SRC_ROOT
    
    if [ ! -d SoapyHackRF ]; then
	git clone https://github.com/pothosware/SoapyHackRF.git
	cd SoapyHackRF
    else
	cd SoapyHackRF
	git pull
    fi
	
    rm -rf build; mkdir build; cd build
    cmake -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/SoapySDR -DCMAKE_MODULE_PATH=$DEPS_INSTALL_DIR/SoapySDR/share/cmake -DLIBHACKRF_INCLUDE_DIR=$DEPS_INSTALL_DIR/libhackrf/include/libhackrf -DLIBHACKRF_LIBRARY=$DEPS_INSTALL_DIR/libhackrf/lib/libhackrf.so -DSOAPY_SDR_INCLUDE_DIR=$DEPS_INSTALL_DIR/SoapySDR/include -DSOAPY_SDR_LIBRARY=$DEPS_INSTALL_DIR/SoapySDR/lib/libSoapySDR.so ..
    make -j $(nproc) || exit 2
    make install
}

##
### Soapy LimeSDR
##
function Soapy_LimeSDR_SDR() {
    cd $SRC_ROOT

    if [ -d LimeSuite/builddir ]; then
	if [ -e $DEPS_INSTALL_DIR/LimeSuite/lib/SoapySDR/$SOAPY_MODULE_VERSION/libLMS7Support.so ]; then
	    cp $DEPS_INSTALL_DIR/LimeSuite/lib/SoapySDR/$SOAPY_MODULE_VERSION/libLMS7Support.so $DEPS_INSTALL_DIR/SoapySDR/lib/SoapySDR/$SOAPY_MODULE_VERSION
	else
	    echo "Error: LimeSuite's SoapySDR module isn't build, skipping..."
	fi
    fi
}

##
### Soapy Remote
##
function Soapy_Remote() {
    cd $SRC_ROOT

    if [ ! -d SoapyRemote ]; then
	sudo apt-get -y install libavahi-client-dev
	git clone https://github.com/pothosware/SoapyRemote.git
	cd SoapyRemote
    else
	cd SoapyRemote
	git pull
    fi
    
    git reset --hard "soapy-remote-0.5.1"
    
    rm -rf build; mkdir build; cd build
    cmake -DCMAKE_INSTALL_PREFIX=$DEPS_INSTALL_DIR/SoapySDR -DCMAKE_MODULE_PATH=$DEPS_INSTALL_DIR/SoapySDR/share/cmake -DSOAPY_SDR_INCLUDE_DIR=$DEPS_INSTALL_DIR/SoapySDR/include -DSOAPY_SDR_LIBRARY=$DEPS_INSTALL_DIR/SoapySDR/lib/libSoapySDR.so ..
    make -j $(nproc) || exit 2
    make install
}

##
### Build SDRangel
##
function build_sdrangel() {
    #
    # This is for a 24 bit samples build. For 16 bit use -DRX_SAMPLE_24BIT=OFF
    #sample_optarg=" -DRX_SAMPLE_24BIT=OFF "
    sample_optarg=" -DRX_SAMPLE_24BIT=ON "
    
    #
    # Additional options on cmake line for partial compilation:
    #    -DBUILD_SERVER=OFF to compile the GUI variant only
    #    -DBUILD_GUI=OFF to compile the server variant only

    ## Default was:
    ##dev_optargs=" -Wno-dev -DDEBUG_OUTPUT=ON "
    ## Silent:
    dev_optargs=" -Wno-dev "
    
    cd $SRC_ROOT

    if [ ! -d sdrangel ]; then
	git clone https://github.com/f4exb/sdrangel.git
	cd sdrangel
    else
	cd sdrangel
	git pull
    fi
    
    rm -rf build; mkdir build; cd build
    cmake $dev_optargs $sample_optarg \
	  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	  -DMIRISDR_DIR=$DEPS_INSTALL_DIR/libmirisdr \
	  -DAIRSPY_DIR=$DEPS_INSTALL_DIR/libairspy \
	  -DAIRSPYHF_DIR=$DEPS_INSTALL_DIR/libairspyhf \
	  -DBLADERF_DIR=$DEPS_INSTALL_DIR/libbladeRF \
	  -DHACKRF_DIR=$DEPS_INSTALL_DIR/libhackrf \
	  -DRTLSDR_DIR=$DEPS_INSTALL_DIR/librtlsdr \
	  -DLIMESUITE_DIR=$DEPS_INSTALL_DIR/LimeSuite \
	  -DIIO_DIR=$DEPS_INSTALL_DIR/libiio \
	  -DPERSEUS_DIR=$DEPS_INSTALL_DIR/libperseus \
	  -DXTRX_DIR=$DEPS_INSTALL_DIR/xtrx-images \
	  -DSOAPYSDR_DIR=$DEPS_INSTALL_DIR/SoapySDR \
	  -DUHD_DIR=$DEPS_INSTALL_DIR/uhd \
	  -DAPT_DIR=$DEPS_INSTALL_DIR/aptdec \
	  -DCM256CC_DIR=$DEPS_INSTALL_DIR/cm256cc \
	  -DDSDCC_DIR=$DEPS_INSTALL_DIR/dsdcc \
	  -DSERIALDV_DIR=$DEPS_INSTALL_DIR/serialdv \
	  -DMBE_DIR=$DEPS_INSTALL_DIR/mbelib \
	  -DCODEC2_DIR=$DEPS_INSTALL_DIR/codec2 \
	  -DSGP4_DIR=$DEPS_INSTALL_DIR/sgp4 \
	  -DLIBSIGMF_DIR=$DEPS_INSTALL_DIR/libsigmf \
	  -DDAB_DIR=$DEPS_INSTALL_DIR/libdab \
	  -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR ..
    make -j $(nproc) || exit 2
    sudo make -j $(nproc) install
    
}

function build_libs() {
    SanityCheck;
    
    aptdec;
    CM265cc;
    LibDAB;
    MBElib;
    SerialDV;
    DSDcc;
    Codec2_FreeDV;
    SGP4;
    LibSigMF;
}

function build_sdrs() {
    SanityCheck;

    Airspy_SDR;
    SDRplay_RSP1_SDR;
    RTL_SDR;
    Pluto_SDR;
    BladeRF_SDR;
    HackRF_SDR;
    Soapy_SDR_SDR;
    LimeSDR_SDR;
    AirspyHF_SDR;
    Perseus_SDR;
    USRP_SDR;
    XTRX_SDR;

    ## Soapy devices
    Soapy_RTL_SDR_SDR;
    Soapy_HackRF_SDR;
    Soapy_LimeSDR_SDR;
    Soapy_Remote
}

function build_test() {
    #    SanityCheck;
    
    #    aptdec;
    #    CM265cc;
    #    LibDAB;
    #    MBElib;
    #    SerialDV;
    #    DSDcc;
    #    Codec2_FreeDV;
    #    SGP4;
    #    LibSigMF;
    
    #    Airspy_SDR;
    #    SDRplay_RSP1_SDR;
    #    RTL_SDR;
    #    Pluto_SDR;
    ## MODIFED    BladeRF_SDR;
    #    HackRF_SDR;
    #    LimeSDR_SDR;
    #    AirspyHF_SDR;
    #    Perseus_SDR;
    #    USRP_SDR;
    #    XTRX_SDR;
    
    ## Soapy
    #    Soapy_SDR_SDR;
    #    Soapy_RTL_SDR_SDR;
    #    Soapy_HackRF_SDR;
    #    Soapy_LimeSDR_SDR;
    #    Soapy_Remote;
    
    #    build_sdrangel;
    :
}

function build_all() {
    SanityCheck;
    build_libs;
    build_sdrs;
    build_sdrangel;
}

function run_SDRangel() {
    if [ -e $INSTALL_DIR/bin/sdrangel ]; then
	optargs=""

	if [ x$OPTION_EXECUTE_FROM_SCRATCH != "x0" ]; then
	    optargs="--scratch"
	fi
	
	if [ x$OPTION_ENABLE_SOAPY != "x0" ]; then
	    optargs="$optargs --soapy"
	fi

	if [ x$OPTION_ENABLE_SHUTTERPRO != "x0" ]; then
	    if [ -e $SHUTTLEPRO_BINARY ]; then
		if [ ! -z $(grep "\[SDRangel\]" ~/.shuttlerc) ]; then
		    if [ -z $(pgrep shuttlepro) ]; then
			if [ -e $SHUTTLEPRO_DEVICE ]; then
			    echo -n "Starting ShuttlePRO..."
			    nohup shuttlepro /dev/input/by-id/usb-Contour_Design_ShuttleXpress-event-if00 > /dev/null 2<&1 &
			    echo -e "\b\b\b: done."
			else
			    echo "ShuttlePRO device is not plugged/available, skipping..."
			fi
		    else
			echo "ShuttlePRO is already running, skipping..."
		    fi
		else
		    echo "SDRangel entry not found in ShuttlePRO ressource file, skipping..."
		fi
	    else
		echo "ShuttlePRO binary not found, skipping..."
	    fi
	fi
	
	#export QT_SCREEN_SCALE_FACTORS=1
	#export QT_SCALE_FACTOR=1
	#export QT_AUTO_SCREEN_SCALE_FACTOR=0
	
	LD_LIBRARY_PATH=$DEPS_INSTALL_DIR/xtrx-images/lib:$DEPS_INSTALL_DIR/SoapySDR/lib:$DEPS_INSTALL_DIR/LimeSuite/lib:$LD_LIBRARY_PATH \
		       $INSTALL_DIR/bin/sdrangel $optargs
	return $?
    fi

    return 1
}

function run_shell() {
    echo " => Starting a sub-shell, within the installation directory ($INSTALL_DIR)..."
    LD_LIBRARY_PATH=$DEPS_INSTALL_DIR/xtrx-images/lib:$DEPS_INSTALL_DIR/SoapySDR/lib:$DEPS_INSTALL_DIR/LimeSuite/lib:$DEPS_INSTALL_DIR/libhackrf/lib:$DEPS_INSTALL_DIR/librtlsdr/lib:$LD_LIBRARY_PATH \
		   PATH=$DEPS_INSTALL_DIR/aptdec/bin:$DEPS_INSTALL_DIR/cm256cc/bin:$DEPS_INSTALL_DIR/serialdv/bin:$DEPS_INSTALL_DIR/dsdcc/bin:$DEPS_INSTALL_DIR/codec2/bin:$DEPS_INSTALL_DIR/libairspy/bin:$DEPS_INSTALL_DIR/libmirisdr/bin:$DEPS_INSTALL_DIR/librtlsdr/bin:$DEPS_INSTALL_DIR/libiio/bin:$DEPS_INSTALL_DIR/libbladeRF/bin:$DEPS_INSTALL_DIR/libhackrf/bin:$DEPS_INSTALL_DIR/LimeSuite/bin:$DEPS_INSTALL_DIR/libairspyhf/bin:$DEPS_INSTALL_DIR/uhd/bin:$DEPS_INSTALL_DIR/SoapySDR/bin:$INSTALL_DIR/bin:$PATH \
		   /bin/bash -c "cd $INSTALL_DIR; exec /bin/bash --login -i"
}

function usage() {
    echo "options are:"
    echo "  -h, --help                 Display this message."
    echo "  -L, --libs                 Build the libraries dependencies."
    echo "  -H, --sdrs                 Build the hardware dependencies."
    echo "  -S, --sdrangel             Build SDRangel binary (using prebuild deps, see above)."
    echo "  -a, --all                  Build all dependencies and SDRangel."
    echo "  -e, --execute              Execute SDRangel."
    echo "      --scratch              Execute SDRangel from scratch (no current config)"
    echo "      --soapy                Execute SDRangel with Soapy SDR support"
    echo "      --shuttle              Execute shuttlepro software if needed."
    echo "      --shell                Open a sub-shell (bash) with LD_LIBRARY_PATH set."
    echo "      --install              Install this script to ~/bin/angel.sh"
    echo "  [no arg]                   Execute SDRangel."
    echo ""
    echo ""
    echo " A file (~/.sdrangel_helper_options.txt) can be used to enable some features by default."
    echo " You simply need to set one or more of these variables to 1, one variable per line. A hash (#) comments a line."
    echo " Available variables: "
    echo "     - OPTION_EXECUTE_FROM_SCRATCH (--scratch)"
    echo "     - OPTION_ENABLE_SOAPY (--soapy)"
    echo "     - OPTION_ENABLE_SHUTTERPRO (--shuttle)"
    echo ""
}


if [ ! -d $SRC_ROOT ]; then
    if [ "$1" != "--install" ]; then
	echo "Please install this script first, using --install option."
	exit 1
    fi
fi

if [ $# -eq 0 ]; then
    run_SDRangel;
    ret=$?
    exit $ret
fi

while test $# -ne 0; do
    case "$1" in
	--libs|-L)
	    SanityCheck;
	    build_libs;
	    ;;
	--sdrs|-H)
	    SanityCheck;
	    build_sdrs;
	    ;;
	--sdrangel|-S)
	    SanityCheck;
	    build_sdrangel;
	    ;;
	--all|-a)
	    SanityCheck;
	    build_libs;
	    build_sdrs;
	    build_sdrangel;
	    ;;
	--execute|-e)
	    ## Execute SDRangel
	    run_SDRangel;
	    ret=$?
	    exit $ret
	    ;;
	--scratch)
	    export OPTION_EXECUTE_FROM_SCRATCH=1
	    ;;
	--soapy)
	    export OPTION_ENABLE_SOAPY=1
	    ;;
	--shuttle)
	    export OPTION_ENABLE_SHUTTERPRO=1
	    ;;
	--shell)
	    run_shell;
	    ;;
	--install)
	    if [ ! -d $SRC_ROOT ]; then
		echo "Creating sources directory $SRC_ROOT..."
		mkdir -p $SRC_ROOT
		echo "Done."
	    fi
	    echo "Installing $0 to ~/bin/angel.sh..."
	    mkdir -p ~/bin
	    cp -vf "$0" ~/bin/angel.sh && \
		chown $USER:$USER ~/bin/angel.sh && \
		chmod 0770 ~/bin/angel.sh
	    echo "Done."
	    ;;
	#	    --test)
	#		build_test;
	#		;;
	*|--help|-h)
	    usage;
	    exit 1
	    ;;
    esac
    
    shift
done

exit 0
