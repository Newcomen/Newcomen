#!/usr/bin/env bash

set -e
set -u
# set -x

# ==============================================================================
# The following variables are required and need to be set to the environment by
# the user:
#
# NEWCOMEN_TARGET_REPO
# NEWCOMEN_SOURCE_REPOS
# GH_TOKEN
#
# The following variables are optional, default values have been provided:
#
# NEWCOMEN_AUTHOR_NAME
# NEWCOMEN_AUTHOR_EMAIL
#
# ==============================================================================
readonly sApplicationName='Newcomen'

sGitUser='potherca-bot'
sGitMail='potherca+bot@gmail.com'

sGithubToken=''
sSourceRepo=''
sTargetRepo=''

declare -a aSourceRepos
# ==============================================================================

function indent() {
    # sed -l basically makes sed replace and buffer through stdin to stdout
    # so you get updates while the command runs and dont wait for the end
    # e.g. npm install | indent
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
    NEWCOMEN_TARGET_REPO="$1"
    NEWCOMEN_SOURCE_REPOS="$2"
    GH_TOKEN="$3"
}

function validateEnvironment() {
    local sErrorMessage=''

    set +u
    if [ -z "${NEWCOMEN_SOURCE_REPOS}" ];then
        sErrorMessage="${sErrorMessage}\n - NEWCOMEN_SOURCE_REPOS"
    fi

    if [ -z "${NEWCOMEN_TARGET_REPO}" ];then
        sErrorMessage="${sErrorMessage}\n - NEWCOMEN_TARGET_REPO"
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
    IFS=',' read -ra aSourceRepos <<< "${NEWCOMEN_SOURCE_REPOS}"

    sTargetRepo="${NEWCOMEN_TARGET_REPO}"

    sGithubToken="${GH_TOKEN}"

    if [ -n "$(echo ${NEWCOMEN_AUTHOR_NAME})" ]; then
        sGitUser="${NEWCOMEN_AUTHOR_NAME}"
    fi

    if [ -n "$(echo ${NEWCOMEN_AUTHOR_EMAIL})" ]; then
        sGitMail="${NEWCOMEN_AUTHOR_EMAIL}"
    fi
}

function storeSource() {
    sSourceRepo="$(git config --get remote.origin.url | cut -f2 -d':' | cut -f1 -d'.')"
}

function setGitUser() {
    printTopic "Setting ${sGitUser}<${sGitMail}> as author"

    git config --global user.email "${sGitMail}"
    git config --global user.name "${sGitUser}"
}

function addRepositoryContent() {
    local sRepo="$1"

    if [ "${sRepo}" == "${sSourceRepo}" ];then
        printStatus "Skipping content from ${sRepo}"
    else
        printStatus "Adding content from ${sRepo}"

        fetchRepositoryContent "${sRepo}" "${sBranch}"
    fi
}

function prepareRepository() {
    rm -Rf .git

    git init | indent
}

function addRemoteToRepository() {
    local sGitRepo="$1"

    if [ -z "${sGithubToken}" ];then
        git remote add origin "https://github.com/${sGitRepo}" | indent
    else
        git remote add origin "https://${sGithubToken}@github.com/${sGitRepo}" | indent
    fi
}

function getBranch() {
    local sBranch='master'

    sBranchName='gh-pages'

    if [ "$(git show-ref ${sBranchName} 2>&1)" ]; then
        sBranch="${sBranchName}"
    fi

    echo "${sBranch}"
}

function commitContent() {
    local sMergeBranch="$1"

    git checkout -b "${sMergeBranch}" | indent
    git add -A | indent
    git commit -a -m "${sApplicationName}: Adding changes from source repositories." | indent
}

function fetchRepositoryContent() {
    local sRepo="$1"

    local sMergeBranch='newcomen-merge-branche'

    prepareRepository

    addRemoteToRepository "${sRepo}"

    commitContent "${sMergeBranch}"

    git fetch | indent

    sBranch="$(getBranch)"
    git checkout "${sBranch}" | indent
    git merge --strategy=recursive --strategy-option=theirs "${sMergeBranch}" -m "${sApplicationName}: Merging content from source repositories." | indent
}

function pushContents() {
    local sBranch="$1"
    git push origin "${sBranch}" | indent
}

function runBuild() {
    local sBranch=''

    printTopic 'Running build'

    setGitUser
    storeSource

    printTopic 'Fetch content from source repositories'
    for sRepo in "${aSourceRepos[@]}"; do
        addRepositoryContent "${sRepo}"
    done

    printTopic 'Fetch content from target repository'
    addRepositoryContent "${sTargetRepo}" "${sBranch}"

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
