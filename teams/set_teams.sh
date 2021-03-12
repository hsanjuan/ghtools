#!/bin/bash

#list=$(cat ipfs-shipyard-repos.txt)
list='
ipfs-geoip
ipfs-hubot
is-ipfs
npm-go-ipfs
npm-go-ipfs-dep
'


for repo in $list; do
    echo "Setting teams for $repo"
    echo
    ./set_team.sh "ipfs-shipyard" "ipfs-shipyard/$repo"
    echo
    continue
    read -p "Is everything ok with https://github.com/ipfs-shipyard/${repo}/settings?[y/n]: " ok
    if [ "$ok" != "y" ]; then
	echo "cancelling"
	exit 1
    fi
    echo "-----------------------------"
    echo
done
