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
#  ./findlinks.sh ~/urls.lst 100 0 2       # Generate and test 100 links formatted for 
                                           # pixeldrain.com at a rate of one attempt every 2s 

# I/O Globals ----
                  # Default Value     Summary
                  #
LIST_FILE=$1      # (/tmp/links.lst)  Where will the list be created, and under what name 
GEN_TOTAL=$2      # (100)             How many links will be generated and test
GEN_TYPE=$3       # (0)               What host company method will be used
FUZZ_DELAY=$4     # (5)               How much delay between attempts         

# Array with indices that correlate with $GEN_TYPE 
# ex. ${HOSTS[0]}="https://pixeldrain.com/u/" 
#
HOSTS=(https://pixeldrain.com/u/ https://mega.nz https://upload.to)
HOST=""

                                              # LEFT                  CENTER                RIGHT       
IFS=""                                        # 1       25      50      75      100     125     150 
tabs 1, 25, 50, 75, 100, 125, 150             # |<- - - | - - - | - - - + - - - | - - - | - - ->|


# This associative array will hold the randomized data portion of a url which is tested and returns
# a successful response code (200). Its elements will be accessed via it's associative indices 
# beginning at 0 and can effectively be parsed with a simple loop and counter.
#
# ex. for x in ${!valid_url[@]}; do echo "$valid_url[$x]; done"  
valid_url=()

# If it already exists, empty the file which will be used to store the randomly generated data set. 
# Otherwise, create a new file to work with
[ -f ${LIST_FILE} ] && echo -n "" > $LIST_FILE || touch $LIST_FILE 


# _ERROR_ $CODE
#
# Summary : Call _ERROR_ with a code value when an anticipated error could occur;
#           Return a visual indication something went wrong, optionally log it (TODO)
#           Ideally correct the issue so the script will continue to execute, or exit with code 1
#
function _ERROR_() {

  ERROR_CODE=$1

  function error_text() {    
    echo -e "$(tput setaf 4)\033[91;1m[ ERROR (code $ERROR_CODE) ] $1 Script may not run as expected [ -- ]$(tput sgr0)\n" 
  }

  case $ERROR_CODE in
    1)
      error_text "Missing or invalid input for argument 1 (gen file). Setting a default value of /tmp/findlinks.lst" ;;
    2)
      error_text "Missing function input argument 2 (Host Identifier). Setting a default value of 0 (Pixeldrain)" ;;
    3)
      error_text "Missing function input argument 3 (Delay). Setting a default value of 5 seconds" ;;
    4)
      error_text "Missing function input argument 1 (Amount). Setting a default value of 100 lines" ;;
    5)
      error_text "4 parameters expected." 
      echo -e "ex.\t$(tput bold)./findlinks.sh genlist.txt 50 0 5\t$tput setaf 2)# Generate and test 50 urls for pixeldrain; delay of 5s\n"
      exit 1
      ;;
    6)
      error_text "Second parameter must be a number greater than 0" 
      exit 1;;
    7)
      error_text "Second parameter must be a number greater than 0" 
      exit 1;;
    8)
      error_text "Second parameter must be a number greater than 0" 
      exit 1;; 
  esac   
      
}

# fuzzAPI - Put this work to good use and find some links!
#           This is fairly passive, and not designed to cause issues.
#           Afterall - I'm a big fan of pixeldrain
#
fuzzAPI() {

  local TRY_COUNT=$GEN_TOTAL    # Fuzz Attempts 
  local SUCCESS_COUNT=0         # Successful Responses
  local ERROR_COUNT=0           # Unsuccessful Responses
  local CURL_RETURN_CODE=""     # HTTP response code
  
  printf "$(date '+%y-%m-%d') : Fuzzing will begin with the folowing parameters:\n\t\tTarget: %s    Attempts: %u    Delay: %u\n" $HOST $TRY_COUNT $FUZZ_DELAY

  while IFS="" read -r LINE; do 

    printf "Current attempt: https://pixeldrain.com/api/file/%s/info\n\n" $LINE
    printf "Filtered Response: "
    curl --silent -w CURL_RETURN_CODE=%{http_code} https://pixeldrain.com/api/file/$LINE/info | awk -F',' '{print $1}' | sed 's/{//g' 
    
    if [ $CURL_RETURN_CODE = 200 ]; then 
      ((SUCCESS_COUNT++))
      # Store link
      # Success_count + 1
      # 
    else
      ((ERROR_COUNT++))
      printf "\nError count: %u " $ERROR_COUNT 
    fi

    sleep $FUZZ_DELAY 
    ((TRY_COUNT--))
  done < $FILE
}

function fixFmt() { cat $LIST_FILE  tr -d "[:blank:]" &>$LIST_FILE ; }


# https://pixeldrain.com 
#
# Details : Hostname is followed with '/u/xxxxxxxx' where x represents an lower case character [a-z] 
#           uppercase character [A-Z] or number [0-9].
#
# Randomized Data Example:  l54eIfWz
#             URL Example:  https://pixeldrain.com/u/api/file/l54eIfWz/info 
#
function genPixelDrain() {

  local LENGTH=8          
  local GEN_STRING=""     
                          
  while [ $GEN_TOTAL -gt 0 ]; do
    GEN_STRING=$(echo -n $(tr -dc A-Za-z0-9 </dev/urandom | head -c $LENGTH))   
    echo "$(echo -e "$z " | tr -d "[:blank:]")" >> $LIST_FILE && (( GEN_TOTAL-- ))   
  done

  # One last cleaning of the file
  fixFmt 

  # Begin Fuzz. Pixeldrain has a public api that does not require authentication (to do this)
  fuzzAPI 

}


# genDataSet 
#                                  
# Summary : genDataSet now uses global variables, and checks have been implemented so
#           this function sorts how the script will handle the input and should there be room to
#           expand, this will serve as a good point between when the list is generated and when
#           the script begins fuzzing against the host. 
#           The call to fuzz is currently made from the generation functions.
#     
function genDataSet() {

  case $GEN_TYPE in
    0)
      genPixelDrain 
      HOST="Pixeldrain"
      ;;
    1)
      # upload.to
      ;;
    2)
      # megaupload
      ;;
    3)
      # etc..
      ;;
  esac 

}



function banner() {

  clear 

  echo -e "\t\t██████╗ ████████╗██████╗ ██╗  ██╗   ███╗   ██╗███████╗████████╗"
  echo -e "\t\t██╔══██╗╚══██╔══╝██╔══██╗██║  ██║   ████╗  ██║██╔════╝╚══██╔══╝"
  echo -e "\t\t██║  ██║   ██║   ██████╔╝███████║   ██╔██╗ ██║█████╗     ██║   "
  echo -e "\t\t██║  ██║   ██║   ██╔══██╗██╔══██║   ██║╚██╗██║██╔══╝     ██║   "
  echo -e "\t\t██████╔╝   ██║   ██║  ██║██║  ██║██╗██║ ╚████║███████╗   ██║   "
  echo -e "\t\t╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   "
  echo -e "\t\t\t\t\t\t"
  echo -e "\t\t\t\t\t\t" 
  echo -e " "
  
  sleep 5
}

# fixArgs 
#
# Summary : This is going to be a lot more functional. Check all the input arguments ahead of time
#           and correct any issues as well as throw error warnings. 
function fixArgs() {

  # These checks do not result in the program exiting 
  # Will likely label these warnings moving forward..
  #
  [ -z $LIST_FILE ] && LIST_FILE='/tmp/findlinks.lst' && _ERROR_ "1"
  [ -z $GEN_TYPE ] && GEN_TYPE=0 && _ERROR_ "2"
  [ -z $FUZZ_DELAY ] && $LENGTH=5 && _ERROR_ "3"      
  [ -z $GEN_TOTAL ] && GEN_TOTAL=100 && _ERROR_ "4"

}


function main() {

  banner
  fixArgs    
  genDataSet 
  exit 0
  
}

# I'm sure there is a better way to go about doing this between  the checks below and the checks found in fixArgs()
# These rudimentary checks ensure the proper amount of parameters are passed and that the last three which expect 
# positive inters do not contain letters.
#
[[ $(($#-1)) -ne 4 ]] && _ERROR_ "5"   
[[ $2 =~ (^[!0-9]) ]] && _ERROR_ "6"
[[ $3 =~ (^[!0-9]) ]] && _ERROR_ "7"
[[ $4 =~ (^[!0-9]) ]] && _ERROR_ "8"

main 
