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
ARGV=$#           #                   **
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
declare -A valid_url=""

# If it already exists, empty the file which will be used to store the randomly generated data set. 
# Otherwise, create a new file to work with
 
#[ -z LIST_FILE ] && echo "" > $LIST_FILE  || touch "$LIST_FILE"  &>/dev/null


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
      error_text "Missing or invalid input for argument 1 (gen file). Setting a default value of /tmp/findlinks.lst" 
      LIST_FILE="/tmp/findlinks.lst" ;;
    2)
      error_text "Missing function input argument 2 (Host Identifier). Setting a default value of 0 (Pixeldrain)" ;;
    3)
      error_text "Missing function input argument 3 (Delay). Setting a default value of 5 seconds" ;;
    4)
      error_text "Missing function input argument 1 (Amount). Setting a default value of 100 lines" ;;
    5)
      error_text "4 parameters expected. See below. " 
      printf "$0 genlist.txt 50 0 5\t%s%s# Generate and test 50 urls for pixeldrain; delay of 5s\n" $(tput setaf 0; tput bold) $(tput setaf 2) && exit 1 #$(tput setaf 2) && exit 1  
      exit 1
      ;;
    6)
      error_text "Second parameter (urls to generate and test) must be a number greater than 0." 
      exit 1;;
    7)
      error_text "Third parameter (filehost identifier) must be a number greater than or equal to 0." 
      exit 1;;
    8)
      error_text "Fourth parameter (delay) must be a number greater than 0." 
      exit 1;; 
  esac   
      
}

# fuzzAPI - Put this work to good use and find some links!
#           This is fairly passive, and not designed to cause issues.
#           Afterall - I'm a big fan of pixeldrain
#
fuzzAPI() {

  local TRY_COUNT=$(cat $LIST_FILE | wc -l)   # Fuzz Attempts 
  local SUCCESS_COUNT=0         # Successful Responses
  local ERROR_COUNT=0           # Unsuccessful Responses
  local CURL_FUZZ_ADDRESS=""    # Full url to fuzz
  local CURL_RETURN_CODE=""     # HTTP response code
  local HTTP_CODE=""
  
  printf "$(tput sgr0; date '+%y-%m-%d')"
  printf "$(tput setaf 32) Fuzzing will begin with the folowing parameters:\n\n$(tput bold;tput setaf 0)Breakdown $(tput setaf 7)\tTarget: %s\n\tAttempts: %u\n\tDelay: %u\n\n" $HOST $TRY_COUNT $FUZZ_DELAY

  printf "\n$(tput setaf 234; tput bold)STATS:"
  while [[ TRY_COUNT -gt 0 ]];  do
   
    ((TRY_COUNT--));
    read -r LINE 

    printf "\n$(tput setaf 31; tput bold)Error count:%s\t\t$(tput setaf 31)Success Count: %s $(tput sgr0)\t$(date +"%H:%M:%S")" $ERROR_COUNT $SUCCESS_COUNT 
    printf "\n$(tput setaf 31; tput bold)Current attempt:$(tput sgr0) https://pixeldrain.com/api/file/$LINE/info\n" "$(tput setaf 131)$LINE$(tput sgr0)"
    printf "$(tput setaf 31; tput bold)Filtered Response:\t $(tput sgr0)"  
    CURL_RETURN_CODE="$(curl --silent -w %{http_code} https://pixeldrain.com/api/file/$LINE/info)"
    HTTP_CODE=$(tail -n1 <<< "$CURL_RETURN_CODE")    

    if [[ $HTTP_CODE  -eq 200 ]]; then 
      printf "$(tput setaf 2)\t200 - Success$(tput sgr0)"
      valid_url[$SUCCESS_COUNT]=$(echo -e "http://pixeldrain.com/u/$LINE") 
      ((SUCCESS_COUNT++))

    elif [[ $HTTP_CODE -eq 404 ]]; then 
      ((ERROR_COUNT++))
      printf "\t404 - Not Found"
    else 
      ((ERROR_COUNT++))
      echo $HTTP_CODE       
    fi

    sleep $FUZZ_DELAY 
    ((TRY_COUNT--))

  done < $LIST_FILE

  echo ${valid_url[@]} >> "./results/results.txt" 
  echo ${valid_url[@]} 

}


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
  rm $LIST_FILE                         
  printf "\n%sGenerating list for Pixeldrain%s ." $(tput bold; tput setaf 6) $(tput sgr0) && sleep 1 && printf "." && sleep 1 \
                                            && printf ".\n" && sleep 1

  while [ $GEN_TOTAL -gt 0 ]; do
    GEN_STRING=$(echo -n $(tr -dc A-Za-z0-9 </dev/urandom | head -c $LENGTH))   
    echo "$(echo -e $GEN_STRING | tr -d "[:blank:]")" >> $LIST_FILE
    ((GEN_TOTAL--))   
  done

  printf "Success:\t%s\n\n" "$(tput bold)$(pwd)/$LIST_FILE$(tput sgr0)"  
  #fixFmt 
 
  # Begin Fuzz
  printf "Done.\n\n"
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
      HOST="Pixeldrain"    
      genPixelDrain 
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
  echo -e " "
  echo -e " "
  echo -e "\t██████╗ ████████╗██████╗ ██╗  ██╗   ███╗   ██╗███████╗████████╗"
  echo -e "\t██╔══██╗╚══██╔══╝██╔══██╗██║  ██║   ████╗  ██║██╔════╝╚══██╔══╝"
  echo -e "\t██║  ██║   ██║   ██████╔╝███████║   ██╔██╗ ██║█████╗     ██║   "
  echo -e "\t██║  ██║   ██║   ██╔══██╗██╔══██║   ██║╚██╗██║██╔══╝     ██║   "
  echo -e "\t██████╔╝   ██║   ██║  ██║██║  ██║██╗██║ ╚████║███████╗   ██║   "
  echo -e "\t╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   "
  echo -e "\t$(tput bold)KBS\n\t$(tput setaf 1)admin@dtrh.net"
  echo -e "\t\t\t\t\t"
  echo -e "\t\t\t\t\t" 
  echo -e "findlinks.sh\t\t\t\tNov 15, 2023$(tput sgr0)"
  echo -e "A versatile script for finding fileshare hosting links"
  
  sleep 2
}

# fixArgs 
#
# Summary : This is going to be a lot more functional. Check all the input arguments ahead of time
#           and correct any issues as well as throw error warnings. 
function fixArgs() {

  # I'm sure there is a better way to go about doing this between  the checks below and the checks found in fixArgs()
  # These rudimentary checks ensure the proper amount of parameters are passed and that the last three which expect 
  # positive inters do not contain letters.
  #
  # [[ $(($#-1)) -ne 4 ]] && printf "%s\n!! $0 requires 4 parameters%s\n$0 genlist.txt 50 0 5\t%s%s# Generate and test 50 urls for pixeldrain; delay of 5s\n" $(tput setaf 1) $(tput setaf 0; tput bold) $(tput setaf 2) && exit 1 #$(tput setaf 2) && exit 1  

  printf "\n%sParameter Test:\n%s" $(tput setaf 6; tput bold) $(tput sgr0) #$(tput setaf sgr0)
  [[ $(($ARGV-1)) -ne 4 ]] && printf "Total Parameters: \t%sGood%s\t%s%s Parameters\n%s"                $(tput setaf 2) $(tput sgr0) $(tput bold) $ARGV       $(tput sgr0) || _ERROR_ "5"
  [[ $GEN_TOTAL =~ (^[!0-9]) ]] && printf "Parameter 2: \t%sGood%s\t%sGenerate and Test %s urls\n%s"    $(tput setaf 2) $(tput sgr0) $(tput bold) $GEN_TOTAL  $(tput sgr0) || _ERROR_ "6"
  [[ $GEN_TYPE =~ (^[!0-9]) ]] && printf "Parameter 3: \t%sGood%s\t%sFilehost target is Pixeldrain\n%s" $(tput setaf 2) $(tput sgr0) $(tput bold) $(tput sgr0)  || _ERROR_ "7"  ## TODO
  [[ $FUZZ_DELAY =~ (^[!0-9]) ]] && printf "Parameter 4: \t%sGood%s\t%sSend delay set to %s%s\n"        $(tput setaf 2) $(tput sgr0) $(tput bold) $(tput sgr0) $FUZZ_DELAY || _ERROR_ "8"

  # These checks do not result in the program exiting 
  # Will likely label these warnings moving forward..
  #
  #[ -z $LIST_FILE ] && LIST_FILE='/tmp/findlinks.lst' && _ERROR_ "1"
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

main 
