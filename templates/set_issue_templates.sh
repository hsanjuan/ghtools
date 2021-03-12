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

function has_templates() {
    local n_files=`ls | wc -l`
    if [ $n_files -eq 0 ]; then
	return 1
    else
	return 0
    fi
}

function write_template() {

    pushd "$REPO" >/dev/null
    
    local templates=".github/ISSUE_TEMPLATE"
    local commit="no"
    
    mkdir -p "$templates"
    pushd "$templates" >/dev/null
    if has_templates; then
     	echo "$REPO ALREADY HAS TEMPLATES"
    elif [ -f "../../ISSUE_TEMPLATE.md" ]; then
	echo "$REPO ALREADY HAS LEGACY TEMPLATE"
    else
	cat <<'EOF' > open_an_issue.md
---
name: Open an issue
about: Only for actionable issues relevant to this repository.
title: ''
labels: need/triage
assignees: ''

---
<!--
Hello! To ensure this issue is correctly addressed as soon as possible by the IPFS team, please try to make sure:

- This issue is relevant to this repository's topic or codebase.

- A clear description is provided. It should includes as much relevant information as possible and clear scope for the issue to be actionable.

FOR GENERAL DISCUSSION, HELP OR QUESTIONS, please see the options at https://ipfs.io/help or head directly to https://discuss.ipfs.io.

(you can delete this section after reading)
-->
EOF
	commit=yes
    fi

    if [ -f "config.yml" ]; then
	echo "$REPO ALREADY HAS config.yml"
    else	
	
	cat <<'EOF' > config.yml
blank_issues_enabled: false
contact_links:
 - name: Getting Help on IPFS
   url: https://ipfs.io/help
   about: All information about how and where to get help on IPFS.
 - name: IPFS Official Forum
   url: https://discuss.ipfs.io
   about: Please post general questions, support requests, and discussions here.
EOF
	commit=yes
    fi
    
    popd >/dev/null
    if [ $commit = "yes" ]; then
	git add -A .github
	git commit -m "Add standard issue template" &>/dev/null
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
write_template

