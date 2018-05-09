#!/bin/bash

checkIfSudo ()
{
        #This makes sure the install script was run with sudo.  It requires root for some actions.
        if [ "$(whoami)" != 'root' ]
        then
                printf "This script requires root permissions.  Please try again with sudo"
                exit 1
        else
        r       eturn 0
        fi
}

runWarning()
{
        clear
        printf "This will update your OS, download and compile code, install packages, and install drivers"
        printf "This will also download some large wordlists so it could take a while to complete."
        read -p "Are you really sure you want to continue?" yn
                case $yn in
                        [Yy]* ) runSetup;;
                        [Nn]* ) exit;;
        * ) printf "Please answer yes to install or no to quit.\n";;
        esac
}

installRequirements()
{
        dpkg --remove-architecture i386   
        apt-get update
        apt-get upgrade -y
        apt install ocl-icd-libopencl1 git build-essential -y
        git clone https://github.com/hashcat/hashcat /opt/hashcat
        cd /opt/hashcat
        git submodule update --init
        make
        git clone https://github.com/hashcat/hashcat-utils /opt/hashcat-utils
        cd /opt/hashcat-utils/src
        make
        cp *.bin ../bin
        cd /tmp
        # For the next command go to the NVidia site and ensure you're downloading the latest Linux drivers
        wget http://us.download.nvidia.com/XFree86/Linux-x86_64/384.69/NVIDIA-Linux-x86_64-384.69.run
        chmod +x ./NVIDIA-Linux-x86_64-384.69.run
        ./NVIDIA-Linux-x86_64-384.69.run
        git clone https://github.com/trustedsec/hate_crack.git /opt/hatecrack
}

getWordlists()
{
        mkdir /opt/wordlists
        git clone https://github.com/danielmiessler/SecLists.git /opt/wordlists/
        cd /opt/wordlists
        wget https://crackstation.net/files/crackstation-human-only.txt.gz
        gunzip crackstation-human-only.txt.gz
        mv crackstation-human-only.txt /opt/wordlists/Passwords
        wget https://crackstation.net/files/crackstation.txt.gz
        gunzip crackstation.txt.gz
        mv crackstation.txt /opt/wordlists/Passwords
        cd /opt/wordlists/Passwords/Leaked-Databases
        tar xvzf rockyou.txt.tar.gz
        mv rockyou.txt ..
        rm rock*.gz
        cd /opt/wordlists
        ls -rt -d -1 $PWD/Passwords/{*,.*} | grep .txt > ./wordlists.txt
}

configureHateCrack()
{
        cp /opt/hatecrack/config.json.example /opt/hatecrack/config.json
        sed -i 's|'/Passwords/hashcat'|'/opt/hashcat'|g' config.json
        sed -i 's|'/Passwords/wordlists'|'/opt/wordlists'|g' config.json
        sed -i 's|'/Passwords/optimized_wordlists'|'/opt/wordlists/optimized'|g' config.json

        sed -i '1 a\ \ "hcatExpanderBin": "expander.bin",' ./config.json
        sed -i '1 a\ \ "hcatCombinatorBin": "combinator.bin",' ./config.json
        sed -i '1 a\ \ "hcatPrinceBin": "pp64.bin",' ./config.json

        cp /opt/hatecrack/wordlist_optimizer.py /opt/hatecrack/wordlist_optimizer.py.original
        sed -i 's/splitlen.app/splitlen.bin/g' /opt/hatecrack/wordlist_optimizer.py
        sed -i 's/rli.app/rli.bin/g' /opt/hatecrack/wordlist_optimizer.py
}

optimizeWordlists()
{
        mkdir /opt/wordlists/optimized
        python /opt/hatecrack/wordlist_optimizer.py /opt/wordlists/wordlists.txt /opt/wordlists/optimized
}

finish()
{
        clear
        echo "Setup complete.  Run CreackerNovice.sh to begin cracking."
}

runSetup()
{
        installRequirements
        getWordlists
        configureHateCrack
        optimizeWordlists
}

checkIfSudo
runWarning
finish