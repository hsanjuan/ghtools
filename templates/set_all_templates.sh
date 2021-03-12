#!/bin/bash

list=$(cat list-ipfs-repos.txt)

for repo in $list; do
    echo "Adding templates for $repo"
    ./set_issue_templates.sh "ipfs/$repo"
    if [ "$ok" = "a" ]; then
	continue
    fi
    read -p "Is everything ok with https://github.com/ipfs/${repo}/issues/new/choose ?[y/n/a]: " ok
    if [ "$ok" == "n" ]; then
	echo "cancelling"
	exit 1
    fi
    echo "-----------------------------"
    echo
done
