#!/bin/bash

ORG="$1"
REPO="$2"

function set_team(){
    name="$1"
    role="$2"

    curl --fail -s -u "$GITHUB_AUTH" -X PUT "https://api.github.com/orgs/$ORG/teams/$name/repos/$REPO"\
    	 -d "{\
    	 	\"permission\": \"$role\"
    	     }"
    if [ $? -eq 0 ]; then
	echo "Team $name correctly set to $role in $REPO"
    fi
}

set_team "javascript" "push"
