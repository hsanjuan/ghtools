#!/bin/bash

set -e

REPO="$1"
README_HEADER="README_header.md"

function clone() {
    if [ -d "$REPO" ]; then
	pushd "$REPO"
	git checkout master
	git pull origin master
	popd
    else 
	git clone "git@github.com:$REPO.git" "$REPO"
    fi
}

function is_archived() {
    archived=`curl -s -u "$GITHUB_AUTH" -X GET "https://api.github.com/repos/$REPO" | jq -r '.archived'`
    if [ "$archived" = "true" ]; then
	return 0
    fi

    return 1
}

function archive() {
    desc="$1"

    if is_archived; then
	echo "$REPO was already archived"
	return
    fi
    
    curl -s -u "$GITHUB_AUTH" -X PATCH "https://api.github.com/repos/$REPO"\
    	 -d "{\
    	 	\"description\": \"$desc\",\
    		\"archived\": true
    	     }" >/dev/null
    if [ $? -eq 0 ]; then
	echo "$REPO was archived successfully"
    fi
}

function archived_description() {
    desc=`curl -s -u "$GITHUB_AUTH" -X GET "https://api.github.com/repos/$REPO" | jq -r '.description'`
    if echo "$desc" | grep -q "ARCHIVED"; then
	echo "$desc"
    else 
	echo "[ARCHIVED] $desc"
    fi
}

function readme_file() {
    find "$REPO" -maxdepth 1 -type f | grep -i readme
}

function readme_header() {
    if [ -f "$README_HEADER" ]; then
	return
    fi

    cat <<'EOF' > "$README_HEADER"
## This repository has been archived!

*This IPFS-related repository has been archived, and all issues are therefore frozen*. If you want to ask a question or open/continue a discussion related to this repo, please visit the [official IPFS forums](https://discuss.ipfs.io).

We archive repos for one or more of the following reasons:

- Code or content is unmaintained, and therefore might be broken
- Content is outdated, and therefore may mislead readers
- Code or content evolved into something else and/or has lived on in a different place
- The repository or project is not active in general

Please note that in order to keep the primary IPFS GitHub org tidy, most archived repos are moved into the [ipfs-inactive](https://github.com/ipfs-inactive) org.

If you feel this repo should **not** be archived (or portions of it should be moved to a non-archived repo), please [reach out](https://ipfs.io/help) and let us know. Archiving can always be reversed if needed.

---

EOF
}

function update_readme() {
    if is_archived; then
	echo "Not updating readme in archived repo $REPO"
	return
    fi
    readme_file=`readme_file`
    if [ "$(head -n 1 $readme_file)" = "## This repository has been archived!" ]; then
	echo "$REPO README already updated"
	return
    fi
    readme_header

    cat "$README_HEADER" "$readme_file" > new_readme.md
    mv new_readme.md "$readme_file"
    pushd "$REPO"
    git add "$(basename $readme_file)"
    git commit -m "Update README with deprecation notice"
    git push origin master
    popd
}

clone
update_readme
new_desc=`archived_description`
echo "new desc $new_desc"
archive "$new_desc"
