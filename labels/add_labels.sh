#!/bin/bash

# set -x
set -e

REPO="$1"
LABELS_FILE="$(echo $REPO | tr '/' '-' )_labels.txt"
COMMIT="$2"
# Renames

function is_archived() {
    archived=`curl -s -u "$GITHUB_AUTH" -X GET "https://api.github.com/repos/$REPO" | jq -r '.archived'`
    if [ "$archived" = "true" ]; then
	return 0
    fi

    return 1
}

function rate_limit(){
    curl -s -v -u "$GITHUB_AUTH" "https://api.github.com/users/hsanjuan" 2>&1 > /dev/null | egrep -o '(X-RateLimit-Remaining|X-RateLimit-Reset):.*$'
}

function get_labels() {
    if [ ! -f "$LABELS_FILE" ]; then
	curl --fail -s -u "$GITHUB_AUTH" "https://api.github.com/repos/$REPO/labels?page=1;per_page=100" | jq -r '.[] | .name+"|"+.color' > "$LABELS_FILE";
	lines=`cat "$LABELS_FILE" | wc -l`
	if [ "$lines" = "100" ]; then
	    curl --fail -s -u "$GITHUB_AUTH" "https://api.github.com/repos/$REPO/labels?page=2;per_page=100" | jq -r '.[] | .name+"|"+.color' >> "$LABELS_FILE";
	fi
    fi
}

function rm_labels() {
    if [ -f "$LABELS_FILE" ]; then
	rm "$LABELS_FILE"
    fi
}

function has_label() {
    if [ -z "$2" ]; then
	egrep -i -q "^$1\|[a-f0-9]{6}\$" "$LABELS_FILE"
    else
	egrep -i -q "^$1\|$2\$" "$LABELS_FILE"
    fi
}

function update_label() {
    name=`echo "$1" | sed 's/ /%20/g'`
    newname="$2"
    color="$3"
    desc="$4"
    echo "Updating $name => '$newname'"
    if [ "$COMMIT" = "commit" ]; then
	curl -s --fail -u "$GITHUB_AUTH" -X PATCH "https://api.github.com/repos/$REPO/labels/$name"\
    	 -d "{\
    		\"new_name\": \"$newname\",\
    		\"description\": \"$desc\",\
    		\"color\": \"$color\"\
    	     }" >/dev/null
    fi
}

function new_label() {
    name="$1"
    color="$2"
    desc="$3"
    echo "Creating label '$name'"
    if [ "$COMMIT" = "commit" ]; then    
	curl -s --fail -u "$GITHUB_AUTH" -X POST "https://api.github.com/repos/$REPO/labels"\
    	 -d "{\
    		\"name\": \"$name\",\
    		\"description\": \"$desc\",\
    		\"color\": \"$color\"\
    	     }" >/dev/null
    fi
}


function line_to_name() {
    echo "$1" |  cut -d '|' -f 1
}

function line_to_color() {
    echo "$1" |  cut -d '|' -f 2 | tr -d '#'
}

function line_to_desc() {
    echo "$1" |  cut -d '|' -f 3
}

function get_line() {
    grep "^$1" listcolors.txt
}

function add_labels() {
    rm_labels
    get_labels
    while read l; do
	name=`line_to_name "$l"`
	color=`line_to_color "$l"`
	desc=`line_to_desc "$l"`
	if has_label "$name" "$color"; then
	    echo "up to date: $name"
	elif has_label "$name"; then
	    update_label "$name" "$name" "$color" "$desc"
	else
	    new_label "$name" "$color" "$desc"
	fi
    done < listcolors.txt
}

function rename_label() {
    current="$1"
    new="$2"
    if has_label "$current"; then
	l=`get_line "$new"`
	if [ -z "$l" ]; then
	    echo "cannot rename $current to unknown label: $new"
	    return
	fi
	c=`line_to_color "$l"`
	d=`line_to_desc "$l"`
	update_label "$current" "$new" "$c" "$d"
    fi
}

function rename_label_or_delete(){
    current="$1"
    new="$2"
    c="$3"
    d="$4"
    filter="$5"
    if has_label "$current"; then
	name=`echo "$current" | sed 's/ /%20/g'`
	length=`curl -s --fail -u "$GITHUB_AUTH" -X GET "https://api.github.com/repos/$REPO/issues?labels=$name&state=$filter" | jq length`
	if [ $length -eq 0 ]; then #deleting
	    echo "deleting unused label $1"
	    if [ "$COMMIT" = "commit" ]; then    
		curl -s --fail -u "$GITHUB_AUTH" -X DELETE "https://api.github.com/repos/$REPO/labels/$name"
	    fi
	else # renaming
	    update_label "$current" "$new" "$c" "$d"
	fi
    fi
}

function rename_to_topic(){
    current="$1"
    topic="$2"
    if has_label "$current"; then
	update_label "$current" "topic/$topic" "3f4b56" "Topic $topic"
    fi
}

function delete_label(){
    name=`echo "$1" | sed 's/ /%20/g'`
    if has_label "$name"; then
	length=`curl -s --fail -u "$GITHUB_AUTH" -X GET "https://api.github.com/repos/$REPO/issues?labels=$name&state=all" | jq length`
	if [ $length -eq 0 ]; then
	    echo "deleting unused label $1"
	    curl -s --fail -u "$GITHUB_AUTH" -X DELETE "https://api.github.com/repos/$REPO/labels/$name"
	else
	    echo "will not delete used label $1"
	fi
    fi
}


function rename_labels() {
    rm_labels
    get_labels
    rename_label "bug" "kind/bug"
    rename_to_topic "documentation" "docs"
    rename_to_topic "docs" "docs"
    rename_to_topic "doc" "docs"    
    rename_label "duplicate" "status/duplicate"
    rename_label "enhancement" "kind/enhancement"
    rename_label "enhancement/feature" "kind/enhancement"
    rename_label "question" "kind/question"
    rename_label "backlog" "status/deferred"
    # rename_label "wontfix" "status/wontfix"
    rename_label "P0 - Critical" "P0"
    rename_label "P1 - High" "P1"
    rename_label "P2 - Medium" "P2"
    rename_label "P3 - Low" "P3"
    rename_label "Priority: Critical" "P0"
    rename_label "priority:high" "P1"
    rename_label "Priority: High" "P1"
    rename_label "priority:low" "P3"
    rename_label "Priority: Low" "P3"
    rename_label "priority:medium" "P2"
    rename_label "Priority: Medium" "P2"
    rename_label "in progress" "status/in-progress"
    rename_label "blocked" "status/blocked"
    rename_label "difficulty:easy" "dif/easy"
    rename_label "Difficulty: Easy" "dif/easy"
    rename_label "difficulty:moderate" "dif/hard"
    rename_label "Difficulty: Moderate" "dif/hard"
    rename_label "difficulty:hard" "dif/expert"
    rename_label "Difficulty: Hard" "dif/expert"
    rename_label "difficulty:medium" "dif/medium"
    rename_label "needs_refining" "need/analysis"
    rename_label "postponed" "status/deferred"
    rename_label "discussion-needed" "need/community-input"
    rename_label "discussion" "need/community-input"
    # rename_label "hint/good-first-issue" "good first issue"
    # rename_label "hint/needs-analysis" "need/analysis"
    # rename_label "hint/needs-author-input" "need/author-input"
    # rename_label "hint/needs-community-input" "need/community-input"
    # rename_label "hint/needs-participation" "need/community-input"
    # rename_label "hint/needs-triage" "need/triage"
    # rename_label "hint/needs-team-input" "need/maintainers-input"
    rename_label "need/maintainer-input" "need/maintainers-input"
    rename_label "ready" "status/ready"

    
    rename_label "testing" "kind/test"
    rename_label "triaging" "need/triage"
    rename_label "waiting on author" "need/author-input"

    rename_to_topic "artwork" "artwork"
    rename_to_topic "bandwidth-reduction" "bandwidth-reduction"
    rename_to_topic "MFS" "MFS"
    # rename_to_topic "RFM" "RFM"
    rename_to_topic "UnixFS" "UnixFS"
    rename_to_topic "api" "api"
    rename_to_topic "badger" "badger"
    rename_to_topic "bandwidth reduction" "bandwidth reduction"
    rename_to_topic "benchmark" "benchmark"
    rename_to_topic "bitswap" "bitswap"
    rename_to_topic "blockervice" "blockervice"
    rename_to_topic "blockstore" "blockstore"
    rename_to_topic "build" "build"
    rename_to_topic "cidv1b32" "cidv1b32"
    rename_to_topic "cleanup" "cleanup"
    rename_to_topic "commands" "commands"
    rename_to_topic "commands:add" "commands:add"
    rename_to_topic "config" "config"
    rename_to_topic "connmgr" "connmgr"
    rename_to_topic "containers + vms" "containers + vms"
    rename_to_topic "core" "core"
    rename_to_topic "core-api" "core-api"
    rename_to_topic "daemon + init" "daemon + init"
    rename_to_topic "datastore" "datastore"
    rename_to_topic "dep change" "dep change"
    rename_to_topic "dependencies" "dependencies"
    rename_to_topic "dht" "dht"
    rename_to_topic "discovery" "discovery"
    rename_to_topic "docs-ipfs" "docs-ipfs"
    rename_to_topic "encryption" "encryption"
    rename_to_topic "filecoin" "filecoin"
    rename_to_topic "files" "files"
    rename_to_topic "filestore" "filestore"
    rename_to_topic "fuse" "fuse"
    rename_to_topic "gateway" "gateway"
    rename_to_topic "gx" "gx"
    rename_to_topic "http-api" "http-api"
    rename_to_topic "icebox" "icebox"
    rename_to_topic "interop" "interop"
    rename_to_topic "interrupt" "interrupt"
    rename_to_topic "ios" "ios"
    rename_to_topic "ipns" "ipns"
    rename_to_topic "libp2p" "libp2p"
    rename_to_topic "ls API" "ls API"
    rename_to_topic "merkledag" "merkledag"
    rename_to_topic "meta" "meta"
    rename_to_topic "mobile" "mobile"
    rename_to_topic "nat" "nat"
    rename_to_topic "note" "note"
    # rename_to_topic "panic" "panic"
    rename_to_topic "perf" "perf"
    rename_to_topic "platforms" "platforms"
    rename_to_topic "portability" "portability"
    rename_to_topic "process" "process"
    rename_to_topic "provider" "provider"
    rename_to_topic "race" "race"
    rename_to_topic "release" "release"
    rename_to_topic "releases" "releases"
    rename_to_topic "repo" "repo"
    rename_to_topic "routing" "routing"
    rename_to_topic "security" "security"
    rename_to_topic "technical debt" "technical debt"
    rename_to_topic "test failure" "test failure"
    rename_to_topic "tools" "tools"
    rename_to_topic "tracking" "tracking"
    rename_to_topic "webui" "webui"
    rename_to_topic "windows" "windows"

    rename_label_or_delete "needs review" "need/review" "ededed" "Needs a review" "open"
    rename_label_or_delete "review" "need/review" "ededed" "Needs a review" "open"
    rename_label_or_delete "P4 - Very Low" "P4" "f9d0c4" "Very low priority" "open"
    rename_label_or_delete "invalid" "status/invalid" "dcc8e0" "Invalid issue" "all"
    rename_label_or_delete "wontfix" "status/wontfix" "dcc8e0" "This will not be addressed" "all"
    rename_label_or_delete "accepted" "status/accepted" "dcc8e0" "This issue has been accepted" "open"
    rename_label_or_delete "WIP" "status/WIP" "dcc8e0" "This a Work In Progress" "open"
    rename_label_or_delete "verify" "need/verification" "ededed" "This issue needs verification" "open"    
}

if is_archived; then
    echo "skipping $REPO is archived"
    exit 0
fi

#echo "<details><summary>Planned label renaming for $REPO</summary>"
# get_labels
rename_labels
add_labels
rate_limit
#echo "</details>"
