#!/bin/bash

## findlinks.sh --------
# 
#  An automated bash script to generate potential links on a fileshare hosting company and test them
#  using curl. Found links are stored in an array and saved to disk.
#  This script is set up for pixeldrain.com links, which have unique identifiers 8 digits long,
#  consisting of upper/lower characters, and numbers.
#  the cGen() function can be called with arguments dictating the length and amount of unique links
#  to generate. And anything else is easily modified within.
#
# 

# Global Variables ---
FILE=$1 
HOST="https://pixeldrain.com/u/"
TSTRING="200 OK"

# Set to nothing, as I processed it earlier in cGen(). "" represents new line, could also be "\n"
IFS=""
_UL="$(tput smul)" && _rUL="$(tput rmul)"
# Array to hold any file hits later..
# This way the hit list can be accessed with   ${validFiles[$x]}
# where $x is a loop variable of indices, ${validFiles[$x]} is one
# element of the array, depending on $x.
declare -a validFiles=()

# Create a fresh new file to be used  as a home
# for the random URL generation
#
#                     #   v Exists v    
cat "$FILE" &>/dev/null && rm $FILE; #  Does not exist 
touch "$FILE"   # Recreate it

# Function to generate lines of alphanumeric strings including upper/lower case letters
# Local variables are used in place of hard coded numbers to to increase similar use case 
# compatibility. Arg 1 for length, arg 2 for amount of unique lines.                         
#                    cGen 8 100  # <- 100x linex at 8 characters long                                

function cGen() {      # $1 $2   #       

  len=$1
  x=$2
  z=$2

  echo -e "$_UL\033[39;1m\n1. Generating unique URL list based off parameters:$_rUL \033[34;1m\t$len Characters long\n\t\t\t$x links to generate." 
  if ! [ $len = "" ]; then len=8; fi  # For if !value
  if [ $x = "" ]; then echo "Remember: Arg1 = length, Arg2 = amount"; fi 
  while [ $x -gt 0 ]; do
    z=$(echo -n $(tr -dc A-Za-z0-9 </dev/urandom | head -c $1))    # <- As it loops counting $x down, 
    echo "$(echo -e "$z " | tr -d "[:blank:]")" >> $FILE && (( x=$x-1 ))  # <- each unique URL is appended to 
  done

}

# fuzzAPI - Put this work to good use and find some links!
#           This is fairly passive, and not designed to cause issues.
#           Afterall - I'm a big fan of pixeldrain
#
fuzzAPI() {

  x=$(cat $FILE | wc -l)
  y=$x
  z=0
  DELAY=2
  while IFS="" read -r LINE; do
    (( x=$x-1 ))
    tput setab 12; echo -ne "\n\033[139;5;1m$(date)$(tput setaf 226) [ OPERATION - FUZZING ] -------------------- [ Testing $x url of $y generated.. $z links so far ] ";tput sgr0;  
    echo -en "$(tput setab 195)"
    echo -e "\nBeginning fuzz: Testing for api response at address:\n\033[30;1mhttps://pixeldrain.com/api/file/\033[31;1m$LINE\033[30;1m/info" # $LINE #& >/dev/null 
    echo -e "$(tput bold)\t\033[36;1m" && echo -ne "API Response:\t "
    curl --silent https://pixeldrain.com/api/file/"$LINE"/info | awk -F',' '{print $3}' | sed 's/}//g' #$LINE  

    sleep 1 
  done < $FILE
}

function banner() {

  clear 
  #echo -e "$(
  echo -e "$(tput setaf 230; tput setab 24)"

  echo -e "                                                                                     "  
  echo -e "                                                                                     "
  echo -e "           ██████╗ ████████╗██████╗ ██╗  ██╗   ███╗   ██╗███████╗████████╗           "
  echo -e "           ██╔══██╗╚══██╔══╝██╔══██╗██║  ██║   ████╗  ██║██╔════╝╚══██╔══╝           "
  echo -e "           ██║  ██║   ██║   ██████╔╝███████║   ██╔██╗ ██║█████╗     ██║              "
  echo -e "           ██║  ██║   ██║   ██╔══██╗██╔══██║   ██║╚██╗██║██╔══╝     ██║              "
  echo -e "           ██████╔╝   ██║   ██║  ██║██║  ██║██╗██║ ╚████║███████╗   ██║              "
  echo -e "           ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝              "
  echo -e "                                                                                     "
  echo -e "                                                                                     "
  echo -en "$(tput sgr0)" 

  tabs 1,35,50,75,100
  echo -e "\n\n\033[36;1mRandom filehost URL Generater/Tester\n\033[36;0mConfigured for www.pixeldrain.com..\n\n\033[31;1mHTTPS://DTRH.NET\t\t\tdtrh.net | admin@\033[1;1m"
  echo -e "\n"

  sleep 5
}

# Empty whitespace can cause parsing issues
function fixFmt() { cat $FILE  tr -d "[:blank:]" &>/tmp/1.txt ; }

# Put it all together in the main function
# A little overkill, but did some return status checks and added some colour.
#

function main() {

  banner 
  cGen 8 100; [[ $? != 0 ]] && echo -e "\033[37;0mList created \033[32;1msuccessfully!" >&2 ||  echo -e "\033[37mSomething went \033[31;1mwrong.." 
  echo -e "\033[37;0mSaved data to \033[32;0m$FILE!\n\033[37;0m\n$_UL\033[39;1m2. Cleaning any whitespace in $FILE$_rUL\n"
  fixFmt 
  fuzzAPI   
  #tput sgr0
  #uGen 
  exit 0
}

main 
