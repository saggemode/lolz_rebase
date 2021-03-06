#!/bin/bash

#
# Lolz Build Script
#

# Lets use Linaro GCC 7.4.x
TOOLCHAIN="$HOME/linaro/bin/arm-eabi-"

ARCHITECTURE="arm"

KERNEL_NAME="LolZ-kernel"

KERNEL_VARIANT="hlte"

KERNEL_VERSION="8.0"

KERNEL_DATE="$(date +"%Y%m%d")"

BUILD_DIR="output_$KERNEL_VARIANT"

KERNEL_IMAGE="$BUILD_DIR/arch/arm/boot/zImage"

COMPILE_DTB="y"

DTB="$BUILD_DIR/arch/arm/boot/dt.img"

ANYKERNEL_DIR="lolz_anykernel"

RELEASE_DIR="release"

NUM_CPUS=""

# ***** ***** ***** ***** ***THE END*** ***** ***** ***** ***** #

COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[1;32m"
COLOR_NEUTRAL="\033[0m"

export ARCH=$ARCHITECTURE

export CROSS_COMPILE="${CCACHE} $TOOLCHAIN"

if [ -z "$NUM_CPUS" ]; then
	NUM_CPUS=`grep -c ^processor /proc/cpuinfo`
fi

if [ "hltekor" == "$KERNEL_VARIANT" ]; then
	KERNEL_DEFCONFIG="lineage_hltekor_defconfig"
elif [ "hltetmo" == "$KERNEL_VARIANT" ]; then
	KERNEL_DEFCONFIG="lineage_hlte_pn547_defconfig"
elif [ "hltechn" == "$KERNEL_VARIANT" ]; then
	KERNEL_DEFCONFIG="lineage_hltechn_defconfig"
else
	KERNEL_VARIANT="hlte" && KERNEL_DEFCONFIG="lineage_hlte_bcm2079x_defconfig"
fi

# Initialize building...
if [ -e $BUILD_DIR ]; then
	if [ -e $BUILD_DIR/.config ]; then
		rm -f $BUILD_DIR/.config
		if [ -e $KERNEL_IMAGE ]; then
			rm -f $KERNEL_IMAGE
		fi
	fi
else
	mkdir $BUILD_DIR
fi
echo -e $COLOR_NEUTRAL"\n building $KERNEL_NAME $KERNEL_VERSION for $KERNEL_VARIANT \n"$COLOR_NEUTRAL
make -C $(pwd) O=$BUILD_DIR $KERNEL_DEFCONFIG
# updating kernel version
sed -i "s;lineageos;$KERNEL_NAME-V$KERNEL_VERSION;" $BUILD_DIR/.config;
make -j$NUM_CPUS -C $(pwd) O=$BUILD_DIR
if [ -e $KERNEL_IMAGE ]; then
	echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
	cp $KERNEL_IMAGE $ANYKERNEL_DIR/
	# compile dtb if required
	if [ "y" == "$COMPILE_DTB" ]; then
		echo -e $COLOR_GREEN"\n compiling device tree blob (dtb)\n"$COLOR_NEUTRAL
		if [ -f $DTB ]; then
			rm -f $DTB
		fi
		chmod 777 scripts/dtbToolCM
		scripts/dtbToolCM -2 -o $DTB -s 2048 -p $BUILD_DIR/scripts/dtc/ $BUILD_DIR/arch/arm/boot/
		# removing old dtb (if any)
		if [ -f $ANYKERNEL_DIR/dtb ]; then
			rm -f $ANYKERNEL_DIR/dtb
		fi
		# copying generated dtb to anykernel directory
		if [ -e $DTB ]; then
			mv -f $DTB $ANYKERNEL_DIR/dtb
		fi
	fi
	echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
	cd $ANYKERNEL_DIR && zip -r9 $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip && cd ..
	echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
	# check and create release folder.
	if [ ! -d "$RELEASE_DIR" ]; then
		mkdir $RELEASE_DIR
	fi
	rm $ANYKERNEL_DIR/zImage && rm $ANYKERNEL_DIR/dtb && mv $ANYKERNEL_DIR/$KERNEL_NAME-$KERNEL_VARIANT* $RELEASE_DIR
	echo -e $COLOR_GREEN"\n Lolz for $KERNEL_VARIANT is baked... now goto '$RELEASE_DIR' folder...\n"$COLOR_NEUTRAL
else
	echo -e $COLOR_RED"\n Building failed... Please fix the derp you made and try again...\n"$COLOR_RED
fi
