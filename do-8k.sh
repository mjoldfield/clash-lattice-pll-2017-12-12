#! /bin/bash
#
# Build script for Lattice Blinky
#
# Needs the development version of Clash, from which this
# script should be run.
#
# Assumes that this directory is a peer of the compiler root
# e.g.
#
#    foo/bar/clash-compiler
#    foo/bar/blinky
#
# We also need a symlink to 'redirect' the verilog output:
#
#   $ cd foo/bar/clash-compiler
#   $ ln -s verilog ../blinky/verilog
#
# To run it:
#
#   $ cd foo/bar/clash-compiler
#   $ ../blinky/do.sh
#

set -xe

# move to blinky dir and clean
(cd ../blinky; ls ; rm -rf verilog/* *.blif *.log *.v obj *.asc *.bin *.exe)

# generate verilog: this has to run from the compiler dir to get the
# dev version of Clash
stack exec -- clash -Wall -hidir ../blinky/obj -odir ../blinky/obj -fclash-hdldir ../blinky --verilog -i../blinky ../blinky/LED1.hs

# Now over to blinky dir
cd ../blinky

# hack error in source
#perl -pi -e 's/\QUSER_SIGNAL_TO_GLOBAL_BUFFER(globalClk)\E/USER_SIGNAL_TO_GLOBAL_BUFFER(globalClk[0])/' \
#     verilog/LED1/LED1/Lattice_ice40Top.v


# generate yosys synthesis script
{
    FILES=`find verilog/ -type f -iname '*.v' | grep -v test`
    for f in $FILES; do
	echo "read_verilog -Iverilog/LED1 $f"
    done
    echo "synth_ice40 -top LED1 -blif led1.blif"
    echo "write_verilog -attr2comment led1.v"
} > synth.ys

yosys -v3 -l synth.log synth.ys

# This is for the iCE40HX1K on the Olimex EVB board
arachne-pnr -d 8k -o led1-8k.asc -p pins-8k.pcf -P ct256 led1.blif
icepack led1-8k.asc led1-8k.bin



