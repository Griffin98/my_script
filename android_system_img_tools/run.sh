#!/bin/bash

##############################################
# Color Codes
##############################################
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BIN_DIR="bin"
IMG_DIR="source"
MOUNT_DIR="mnt"
OUT_DIR="out"
SPARSE_IMG="${IMG_DIR}/system_sparse.img"
RAW_IMG="${IMG_DIR}/system_raw.img"
OUTPUT_IMG="${OUT_DIR}/system.img"
SIMG2IMG="${BIN_DIR}/simg2img"
MAKEEXT4FS="${BIN_DIR}/make_ext4fs"

extract_img()
{
if [ ! -d $IMG_DIR ]
then
	mkdir $IMG_DIR
fi

echo -e "${YELLOW}\nPlace .lz4 file in the source folder and hit enter...${NC}"
read fake

if [ ! -f $IMG_DIR/*.lz4 ]
then
	echo -e "${RED}\nDidn't found any firmware to extract, makesure to copy one and re-run the script."
	exit
else
	file_name=$(find -iname *.lz4)
fi

read -p "Found: $file_name would you like to proceed (Y/N):" ch
if [[ $ch == 'n' || $ch == 'N' ]]
then
	echo -e "${YELLOW}Enter complete path of the .lz4 file below. ${NC}"
	read -p "Path: " file_name
fi

echo -e "\n${YELLOW}Extracting .lz4...${NC}"
lz4 -d $file_name $SPARSE_IMG
echo -e "\n${YELLOW}Converting sparse img to raw img... ${NC}"
./${SIMG2IMG} ${SPARSE_IMG} ${RAW_IMG}

}

unpack_n_mount()
{
if [ ! -f $RAW_IMG ]
then
	echo -e "${RED}Cannot find raw image to mount, Extract the firmware first${NC}"
	exit
else
	echo -e "\n${YELLOW}Mounting raw img to mnt directory... ${NC}"
	
	if [ ! -d $MOUNT_DIR ]
	then
		mkdir $MOUNT_DIR
	fi
	
	sudo mount -t ext4 -o loop,rw,sync ${RAW_IMG} ${MOUNT_DIR}
fi
}

repack_n_unmount()
{

if [ ! -f $RAW_IMG ]
then
	echo -e "${RED}Cannot find raw image, Extract the firmware first${NC}"
	exit
else
	echo -e "${YELLOW}\nPacking ${MOUNT_DIR}/ to .img...${NC}"

	if [ ! -d $OUT_DIR ]
	then
		mkdir $OUT_DIR
	fi

	size=$(stat -c%s ${RAW_IMG})
	sudo ${MAKEEXT4FS} -s -l ${size} -a system ${OUTPUT_IMG} ${MOUNT_DIR}/
	sudo chmod 644 ${OUTPUT_IMG}
	sudo chown -R ${whoami}:${whoami} ${OUTPUT_IMG}
	sudo umount ${MOUNT_DIR}
	sudo rm -rf ${MOUNT_DIR}
fi
}

main()
{
clear
echo -e "${GREEN}\n\n===================================================="
echo -e "\t Android System Image Tools v0.1"
echo -e "====================================================\n\n"
echo -e "1. Extract img from .lz4"                 
echo -e "2. Mount image"
echo -e "3. Repack image \n ${NC}"
read -p "Enter your choice: " choice

case $choice in 
	1) 
	extract_img
	;;
	
	2)
	unpack_n_mount
	;;
	
	3)
	repack_n_unmount
	;;

esac
}

while true
do
	main
done

