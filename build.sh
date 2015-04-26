#!/usr/bin/env bash

set -e
set -u

# ==============================================================================
# The following variables are required and need to be set to the environment by
# the user:
#
# GH_PAGES_TARGET_REPO
# GH_PAGES_SOURCE_REPOS
# GH_TOKEN
#
# The following variables are optional, default values have been provided:
#
# IW_AUTHOR_NAME
# IW_AUTHOR_EMAIL
#
# ==============================================================================
readonly sApplicationName='InstantWebsite'

sGitUser='potherca-bot'
sGitMail='potherca+bot@gmail.com'

sTargetRepo=''
sGithubToken=''

declare -a aSourceRepos

# sed -l basically makes sed replace and buffer through stdin to stdout
# so you get updates while the command runs and dont wait for the end
# e.g. npm install | indent
function indent() {
  # if an arg is given it's a flag indicating we shouldn't indent the first line,
  # so use :+ to tell SED accordingly if that parameter is set, otherwise null
  # string for no range selector prefix (it selects from line 2 onwards and then
  # every 1st line, meaning all lines)
  local c="${1:+"2,999"} s/^/       /"
  case $(uname) in
    Darwin) sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
    *)      sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

function printError() {
  echo
  echo -e " !     ERROR: $*" | indent no_first_line_indent
  echo
}

function printTopic() {
    echo
    echo "=====> $*"
}

function printStatus() {
    echo "-----> $*"
}

function setEnvironmentFromParamters() {
    GH_PAGES_TARGET_REPO="$1"
    GH_PAGES_SOURCE_REPOS="$2"
    GH_TOKEN="$3"
}

function validateEnvironment() {
    local sErrorMessage=''

    set +u
    if [ -z "${GH_PAGES_SOURCE_REPOS}" ];then
        sErrorMessage="${sErrorMessage}\n - GH_PAGES_SOURCE_REPOS"
    fi

    if [ -z "${GH_PAGES_TARGET_REPO}" ];then
        sErrorMessage="${sErrorMessage}\n - GH_PAGES_TARGET_REPO"
    fi

    if [ -z "${GH_TOKEN}" ];then
        sErrorMessage="${sErrorMessage}\n - GH_TOKEN"
    fi
    set +u

    if [ -n "${sErrorMessage}" ];then
        sErrorMessage="Please make sure the following variable(s) are set in the environment: ${sErrorMessage}"

        printError "${sErrorMessage}"
        exit 65
    fi

}

function setVariables() {
    IFS=',' read -ra aSourceRepos <<< "${GH_PAGES_SOURCE_REPOS}"

    sTargetRepo="${GH_PAGES_TARGET_REPO}"

    sGithubToken="${GH_TOKEN}"

    if [ -n "$(echo ${IW_AUTHOR_NAME})" ]; then
        sGitUser="${IW_AUTHOR_NAME}"
    fi

    if [ -n "$(echo ${IW_AUTHOR_EMAIL})" ]; then
        sGitMail="${IW_AUTHOR_EMAIL}"
    fi

}

function setGitUser() {
    printTopic "Setting ${sGitUser}<${sGitMail}> as author"

    git config --global user.email "${sGitMail}"
    git config --global user.name "${sGitUser}"
}

function prepareRepository() {
    local sGitRepo="$1"

    rm -Rf .git

    git init | indent

    if [ -z "${sGithubToken}" ];then
        git remote add origin "https://github.com/${sGitRepo}" | indent
    else
        git remote add origin "https://${sGithubToken}@github.com/${sGitRepo}" | indent
    fi
}

function fetchRepositoryContent() {
    local sGitRepo="$1"

    #@CHECKME: If $sGitRepo is the repo the build was triggered for git should
    #          report "Everything up to date". Can there be other side-effects?
    printStatus "Fetching contents from ${sGitRepo}"
    prepareRepository "${sGitRepo}"
    git fetch | indent
}

function getBranch() {
    local sBranch='master'

    sBranchName='gh-pages'

    if [ "$(git rev-parse --git-dir > /dev/null 2>&1)" ] && [ -n "$(git show-ref refs/heads/${sBranchName})" ]; then
        sBranch="${sBranchName}"
    fi

    echo "${sBranch}"
}

function mergeContents() {
    local sBranch="$1"
    local sMergeBranch='instant-web-merge-branche'

    git checkout -b "${sMergeBranch}" | indent
    git add -A | indent
    git commit -m "${sApplicationName}: Adding changes from source repositories." | indent
    git checkout "${sBranch}" | indent
    git merge --strategy-option theirs "${sMergeBranch}" -m "${sApplicationName}: Merging content from source repositories." | indent
}

function pushContents() {
    local sBranch="$1"
    git push origin "${sBranch}" | indent
}

function runBuild() {
    printTopic 'Running build'

    setGitUser

    printTopic 'Fetch content from source repositories'
    for sRepo in "${aSourceRepos[@]}"; do
        fetchRepositoryContent "${sRepo}"
        git pull origin master
    done

    printTopic 'Fetching content from target repository'
    fetchRepositoryContent "${sTargetRepo}" "${GH_TOKEN}"

    sBranch="$(getBranch)"

    printTopic 'Merging content from source repositories in target repository'
    mergeContents "${sBranch}"

    printTopic 'Sending merged content to target repository'
    pushContents "${sBranch}"

    echo 'Done.'
}

function run() {
    if [ "${#}" -eq 3 ];then
        setEnvironmentFromParamters $@
    fi

    validateEnvironment
    setVariables

    runBuild
}

run $@

#EOF
