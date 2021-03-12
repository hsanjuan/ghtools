#!/bin/bash

#list=$(cat list-ipfs-repos.txt)
list='
go-ds-swift
project-operations
go-ipfs-files
community-calls-reminder
iptb-plugins
go-ipfs-http-client
go-ds-bench
js-ipfs-unixfs-importer
js-ipfs-unixfs-exporter
benchmarks
go-ds-bolt
roadmap
local-offline-collab
community-call-helper
go-ipfs-example-plugin
go-graphsync
js-core
interface-go-ipfs-core
camp.ipfs.io
package-managers
go-ds-crdt
camp
gomod
hang-fds
js-ipfs-repo-migrations
go-prompt
js-ipfs-utils
go-peertaskqueue
go-libp2p-dns-router
go-filestore
metrics
ipfs-docs-v2
devgrants
browser-design-guidelines
go-ipfs-pinner
go-ds-badger2
DAGger
go-ds-bitcask
mobile-design-guidelines
go-car
js-datastore-idb
test-plans
'

for repo in $list; do
     echo "Setting labels for $repo"
    echo
    lines1=`./add_labels.sh "ipfs/$repo" | tee out1 | wc -l`
    echo
    # read -p "Is everything ok in this preview?[y/n]: " ok
    # if [ "$ok" != "y" ]; then
    # 	echo "cancelling"
    # 	exit 1
    # fi

    lines2=`./add_labels.sh "ipfs/$repo" commit | tee out2 | wc -l`
    if [ $lines1 -ne $lines2 ]; then
	echo "PREVIEW"
	echo
	cat out1
	echo
	echo ---
	echo "CHANGES"
	echo
	cat out2
    
	read -p "Is everything ok with https://github.com/ipfs/${repo}/labels ?[y/n]: " ok
	if [ "$ok" != "y" ]; then
	    echo "cancelling"
	    exit 1
	fi
    else
	cat out2
    fi
    
    echo "-----------------------------"
    echo
done
