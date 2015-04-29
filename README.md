---
permalink: /
---

# [Newcomen]

[![Project Stage Badge: Development]][Project Stage Page] ![License Badge]

## Introduction

This projects contains a simple script and some documentation explaining how to
create a setup that hosts a website on [Github Pages] without
mixing the content of the website with the website's templates and resources.

## Setup

For this to work, the following is required: 3 Github repositories and 2 builds.

### Repositories

Each repository has *one* single responsibility and contains *one* type of
content:

 1. templates and resources that make up the website
 2. the content to be placed in the templates
 3. generated code

The generated website will be available from `http://[repository-name].github.io`
or `http://[user-name].github.io/[repository-name]` depending on whether the
Github repository is a User (or Organization) Page or a Project Page.

### Builds

Both the template and the content repository require an build to merge both
sources and push them to the Github Pages repository. Most other
services (like Travis, Codeship, Wercker, etc.) will create a web-hook that will
automatically trigger a build on each commit to the `master` branch for each
repository.

This build consists of a set of environmental variables to feed the build script
and a line of code to fetch and run the build script.

#### Environmental Variables

The following variables are required and need to be set to the environment for
the script to properly function:

 - `NEWCOMEN_TARGET_REPO`
 - `NEWCOMEN_SOURCE_REPOS`
 - `GH_TOKEN`

##### `NEWCOMEN_TARGET_REPO`

The `NEWCOMEN_TARGET_REPO` should contain the repository name the Github Pages
website is to be served from, in the following format: `user-name/repository-name`.
For instance `potherca/newcomen-demo-site`  

##### `NEWCOMEN_SOURCE_REPOS`

The `NEWCOMEN_SOURCE_REPOS` should contain the repository names of the sources
the website should be built from. It takes the format of a comma separated list,
for instance  `potherca/newcomen-demo-content,potherca/newcomen-demo-templates`.

The source repositories should be listed in order of importance, that is to say,
the most important repository should be the first in the list, followed by the
less important, and so on.

In the case that a file is present in more than one repository, the file from
the most important repository (most foremost in the list) will take precedence.

##### `GH_TOKEN`
Each repository (both target and sources) need to be accessible from Codeship.
For Github repositories this can be achieved by creating a [Github token] and
setting that in the `GH_TOKEN` environmental variable.

##### Other options

By default, all commits to the target repository will be done using the
[Potherca Bot]. To use a different author the following variables can be set to
alter the author name and email:

 - `NEWCOMEN_AUTHOR_NAME`
 - `NEWCOMEN_AUTHOR_EMAIL`

#### Build Script

The following command will fetch and run the build script from this repository
with the environmental variables:

    curl -sS https://raw.githubusercontent.com/Newcomen/Newcomen/master/build.sh | bash

### Variations

The content that the target repository should be build from can reside in more
than two repositories. Simply add more repository names to the list in the
`NEWCOMEN_SOURCE_REPOS` variable.

## About the name

In the 1886 novella by Robert Louis Stevenson `Strange Case of Dr Jekyll and Mr Hyde`, *Newcomen* is an inspector from Scotland Yard tasked with the inquiries regarding the murder of Sir Danvers Carew. Together with Utterson (who plays a pivotal role in the story) he explores Hyde's loft in Soho.

The inspector does not have much of a contribution to the story other than observe the effects of Jekyll's actions through Mr. Hyde and help the story along. This seemed a nice fit for this project.

Also, all of the other character's names were already taken.

[Project Stage Badge: Development]: http://img.shields.io/badge/Project%20Stage-Development-yellowgreen.svg
[Project Stage Page]: http://bl.ocks.org/potherca/raw/a2ae67caa3863a299ba0
[License Badge]: http://img.shields.io/:license-GPL--3.0-blue.svg
[Github Pages]: https://pages.github.com/
[Github token]: https://github.com/blog/1509-personal-api-tokens
[Potherca Bot]: https://github.com/potherca-bot
[Newcomen]: https://github.com/potherca/Newcomen/
