#!/bin/bash


list='
aegir-test-repo
archives
astralboot
badgerds-upgrade
benchmark-js.ipfs.io
bitswap-ml
browser-process-platform
ci-sync
ci-websites
community-call-helper
community-calls-reminder
conf.ipfs.io
datatogether
developer-meetings
dht-node
dynamic-data-and-capabilities
eslint-config-aegir
fs-stress-test
gx-workspace
interface-pull-blob-store
ipfs-metrics
ipfs-nodeschool
ipfs-pages
ipfs-performance-profiling
ipfs-sharness-tests
jest-environment-aegir
js-waffle
package-managers
papers
pdd
project-operations
research-bitswap
sig-blockchain-data
sprint-helper-bot
starlog
user-research
webrtcsupport
Websiter
'

for repo in $list; do
    echo "Triggering archival for $repo"
    echo
    ./archive.sh "ipfs/$repo"
    echo
    read -p "Is everything ok with ipfs/${repo}?[y/n]: " ok
    if [ "$ok" != "y" ]; then
	echo "cancelling"
	exit 1
    fi
    echo "-----------------------------"
    echo
done
