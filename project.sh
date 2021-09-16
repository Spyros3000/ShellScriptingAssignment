#!/bin/bash

printFile(){
    while read -r id1 lastname firstname gender birthday creationdate locationip browserused
    do
        case "$id1" in \#*) continue ;; esac
        printf "ID: %s\n" "$id1"
        printf "Lastname: %s\n" "$lastname"
        printf "Firstname: %s\n" "$firstname"
        printf "Gender: %s\n" "$gender"
        printf "Birthday: %s\n" "$birthday"
        printf "CreationDate: %s\n" "$creationdate"
        printf "LocationIp: %s\n" "$locationip"
        printf "BrowserUsed: %s\n\n" "$browserused"
    done < "$file"
}

printId(){
    while read -r id1 lastname firstname gender birthday creationdate locationip browserused
    do
        case "$id1" in $idToFind)
        printf "%s %s %s\n" "$firstname" "$lastname" "$birthday"
        exit 1;;
        esac
    done < "$file"
}

printFirstnames(){
    while read -r id1 lastname firstname gender birthday creationdate locationip browserused
    do
        sort -k3,3 -u --field-separator='|' | cut -d "|" -f 3
        echo "$line"
    done < "$file"
}

printLastnames(){
    while read -r id1 lastname firstname gender birthday creationdate locationip browserused
    do
        sort -k2,2 -u --field-separator='|' | cut -d "|" -f 2
        echo "$line"
    done < "$file"
}

printBornSince(){
    while read -r id1 lastname firstname gender birthday creationdate locationip browserused
    do
        if [[ "$birthday" > "$bornSinceDate" ]]; then
            case "$id1" in \#*) continue ;; esac
            printf "%s|%s|%s|%s|%s|%s|%s|%s\n" "$id1" "$lastname" "$firstname" "$gender" "$birthday" "$creationdate" "$locationip" "$browserused"
        fi
    done < "$file"
}

printBornUntil(){
    while read -r id1 lastname firstname gender birthday creationdate locationip browserused
    do
        if [[ "$birthday" < "$bornUntilDate" ]]; then
            case "$id1" in \#*) continue ;; esac
            printf "%s|%s|%s|%s|%s|%s|%s|%s\n" "$id1" "$lastname" "$firstname" "$gender" "$birthday" "$creationdate" "$locationip" "$browserused"
        fi
    done < "$file"
}

printSinceUntil(){
    while read -r id1 lastname firstname gender birthday creationdate locationip browserused
    do
        if [[ "$birthday" > "$bornSinceDate" && "$birthday" < "$bornUntilDate" ]]; then
            case "$id1" in \#*) continue ;; esac
            printf "%s|%s|%s|%s|%s|%s|%s|%s\n" "$id1" "$lastname" "$firstname" "$gender" "$birthday" "$creationdate" "$locationip" "$browserused"
        fi
    done < "$file"
}

printBrowsers(){
    printf "%s \n" "TODO: Θέλει βελτίωση, κανονικά οι στήλες πρέπει να είναι ανάποδα."
    while read -r id1 lastname firstname gender birthday creationdate locationip browserused
    do
        cut -d "|" -f 8 | sort | uniq -c
    done < "$file"
}

editColumn(){
    IFS=',' # split on comma characters
    array=($OPTARG) # use the split+glob operator
    IFS='|'
    while read -r id1 lastname firstname gender birthday creationdate locationip browserused
    do
        case "$id1" in "${array[0]}")
          case "${array[1]}" in
            id1) columnContent=$id1 columnName="id1" ;;
            lastname) columnContent=$lastname columnName="lastname" ;;
            firstname) columnContent=$firstname columnName="firstname" ;;
            gender) columnContent=$gender columnName="gender" ;;
            birthday) columnContent=$birthday columnName="birthday" ;;
            creationdate) columnContent=$creationdate columnName="creationdate" ;;
            locationip) columnContent=$locationip columnName="locationip" ;;
            browserused) columnContent=$browserused columnName="browserused" ;;
          esac
        #awk -F'[|]' -i inplace '{ gsub(/"$columnID"/, "${array[2]}") }' "$file" <-- Tried to solve this with awk; failed and used sed.
        sed -i'' "s/$columnContent/${array[2]}/g" "$file"
        printf "%s \n%s \n" "File edited, replaced the content of column ${green}$columnName${normal} \
(was: ${green}$columnContent${normal})."\
        "Open it with ${green}vi $file${normal} to see for yourself."
        exit 1;;
        esac
      done < "$file"
}

usage(){
    printf "\n%s \n\n" "${bold}USAGE${normal}"
    printf "%s \n\n" "$0 [-f <filename>] [-id <id>] [--firstnames] [--lastnames] [--born-since <dateA>] [--born-until <dateB>] [--browsers] [--edit <id> <column> <value>]"

    printf "%s \n\n" "${bold}NOTES${normal}"

    printf "%s \n" "* Most arguments are optional and can be ignored."
    printf "%s \n" "* -f is needed in order to parse any other argument."
    printf "%s \n\n" "* --edit is the only argument that writes into the file, changing it."

    printf "%s \n\n" "${bold}EXAMPLES${normal}"

    printf "%s \n" "./myscript.sh"
    printf "%s \n" "./myscript.sh -f users.dat -id 512"
    printf "%s \n" "./myscript.sh -f users.dat --firstnames"
    printf "%s \n" "./myscript.sh -f users.dat --born-since 2001-09-11 --born-until 2017-01-01"
    printf "%s \n" "./myscript.sh -f users.dat --edit 256 browserused Firefox"
}

# ==============Main Function==============

# Some initialisations
AM=15377
IFS='|'

# Colors & bold letters (cosmetic things). Used in editColumn() & usage().
bold=$(tput bold)
green=$(tput setaf 2)
normal=$(tput sgr0)

# If only the script name is called (no arguments), print the registry number (AM).
if [ "$#" -eq 0 ]
    then printf "%s\n" "$AM"
    exit 1
fi

# If only an argument is called (possible user error, since the requirements state that
# the script can take 0 or >=2 arguments) show some clues about the correct use of the script.
if [ "$#" -eq 1 ]
    then usage
    exit 1
fi

# For later, used with--born-since and --born-until
(( counterOfBorn = 1 ))
$flagOfBorn

# Transform long options to short ones (getopts can only handle one-character arguments)
for arg in "$@"; do
  shift
  case "$arg" in
    "-id") set -- "$@" "-d" ;;
    "--firstnames") set -- "$@" "-i" ;;
    "--lastnames")   set -- "$@" "-l" ;;
    "--born-since")   set -- "$@" "-s" ;;
    "--born-until")   set -- "$@" "-u" ;;
    "--browsers")   set -- "$@" "-b" ;;
    "--edit")   set -- "$@" "-e" ;;
    "--help")   set -- "$@" "-h" ;; #Bonus, not needed
    *)        set -- "$@" "$arg"
  esac
done

# We execute two loops in this step, because we need to assign a file
# to the variable $file before the other options are loaded.
while getopts ":f:d:ils:u:be:h" opt; do
  case "$opt" in
    f)
      file=$OPTARG
      if [ "$#" -eq 2 ]
        then printFile
      fi
      ;;
  esac
done

OPTIND=1
while getopts ":f:d:ils:u:be:h" opt; do
  case "$opt" in
    d)
      idToFind=$OPTARG
      printId
      ;;
    i)
      printFirstnames
      ;;
    l)
      printLastnames
      ;;
    s)
      (( counterOfBorn-- ))
      flagOfBorn=true
      bornSinceDate=$OPTARG
      ;;
    u)
      (( counterOfBorn++ ))
      flagOfBorn=true
      bornUntilDate=$OPTARG
      ;;
    b)
      printBrowsers
      ;;
    e)
      editColumn
      ;;
    h)
      usage
      ;;
    \?)
      printf "%s \n" "Invalid option: -$OPTARG"
      ;;
  esac
done
shift "$(( OPTIND - 1 ))" # remove options from positional parameters

if [ $counterOfBorn -eq 0 ] && [ $flagOfBorn ]
    then printBornSince
elif [ $counterOfBorn -eq 2 ] && [ $flagOfBorn ]
    then printBornUntil
else [ $counterOfBorn -eq 1 ] && [ $flagOfBorn ]
    printSinceUntil
fi


