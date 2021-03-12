#!/bin/bash

set -e

REPO="$1"

function clone() {
    if [ -d "$REPO" ]; then
	pushd "$REPO" >/dev/null
	git checkout master &>/dev/null
	git pull origin master &>/dev/null
	if [ $? -ne 0 ]; then
	    echo "ERROR PULLING"
	fi
	popd >/dev/null
    else 
	git clone "git@github.com:$REPO.git" "$REPO" &>/dev/null
	if [ $? -ne 0 ]; then
	    echo "ERROR CLONING"
	fi
    fi
}

function is_archived() {
    archived=`curl -s -u "$GITHUB_AUTH" -X GET "https://api.github.com/repos/$REPO" | jq -r '.archived'`
    if [ "$archived" = "true" ]; then
	return 0
    fi
    return 1
}

function has_welcome_config() {
    # TODO: check if the same as last version or different (for upgrades).
    if [ -f "config.yml" ]; then
	return 0
    else
	return 1
    fi
}

function write_configs() {

    local configtempl="$(pwd)/config.yml"
    pushd "$REPO" >/dev/null
    
    local github=".github"
    local commit="no"
    
    mkdir -p "$github"
    pushd "$github" >/dev/null
    if has_welcome_config; then
     	echo "$REPO ALREADY HAS config.yml"
    else
	cp "$configtempl" config.yml
	commit=yes
    fi

    if [ $commit = "yes" ]; then
	git add -A config.yml
	git commit -m "Add autocomment configuration" &>/dev/null
	git push origin master &>/dev/null
	if [ $? -ne 0 ]; then
	    echo "$REPO: ERROR PUSHING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	fi
    fi
    popd >/dev/null
}


if is_archived "$REPO"; then
    echo "Skipping archived $REPO"
    exit 1
fi
clone
# pushd "$REPO" >/dev/null
# sub=`git log -1 --pretty='%s'`
# if [ "$sub" = "Add autocomment configuration" ]; then
#     echo "$REPO needs fixing"
#     git commit -m 'fix(ci): add empty commit to fix lint checks on master' --allow-empty
#     git push origin master 2>/dev/null
# fi

# popd >/dev/null
write_configs
