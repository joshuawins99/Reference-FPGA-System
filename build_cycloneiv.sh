#!/bin/bash
rm -f main.sof
rm -f file_list.qsf
rm -rf cycloneiv_quartus/db
rm -rf cycloneiv_quartus/incremental_db
rm -rf cycloneiv_quartus/output_files

cd cc65
./build.sh
cd ../rtl
echo -n '`define version_string ' > version_string.svh
if [ "$1" = -build ]; then
    if [ "$2" = REL ]; then
        echo -n '"' >> version_string.svh
        echo -n "REL " >> version_string.svh
        git rev-parse --verify HEAD | cut -c1-7 | xargs echo -n >> version_string.svh
    else
        echo -n '"' >> version_string.svh
        echo -n "DEV " >> version_string.svh
        echo -n $2 >> version_string.svh
    fi
else 
    echo -n '"' >> version_string.svh
    echo -n "DEV " >> version_string.svh
    echo -n "1234567" >> version_string.svh
fi
#git rev-parse --verify HEAD | cut -c1-7 | xargs echo -n | sed -e 's/^/"/' >> version_string.svh
echo -n ' ' >> version_string.svh
date --date 'now' '+%a %b %d %r %Z %Y' | sed -e 's/$/"/' -e 's/,/","/g' >> version_string.svh

#c:/intelFPGA_lite/20.1/quartus/bin64/quartus_sh --flow compile ../main.qpf
cd ..
./convert_filelist.sh rtl/rtl_filelist.txt --quartus
cd rtl/
/root/altera_lite/24.1std/quartus/bin/quartus_sh --flow compile ../cycloneiv_quartus/main.qpf
mv ../cycloneiv_quartus/output_files/main.sof ../main.sof
#/root/intelFPGA_lite/23.1std/quartus/bin/quartus_cpf  --option=bitstream_compression=off -c ../output_files/main.sof ../main.rbf
#/root/intelFPGA_lite/23.1std/quartus/bin/quartus_cpf  -c -q 12.0MHz -g 3.3 -n p ../output_files/main.sof ../main.svf