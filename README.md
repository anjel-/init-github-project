# Project: init-github-project
The aim of this project is to facilitate the creation of a new project on Github.com
It contains a script to create a new local project and a Github repo for it

## Quickstart

Clone the project repo
```
git clone https://github.com/anjel-/init-github-project.git
```
Change to the workspace folder - the folder that will contain the project
and run this script. The script needs three parameters:
a command INIT, a name of the project and a short description of the project.
You also need to setup an environmental parameter GIT_USER with your Github user name like GIT_USER="anjel-"

```
cd $WORKSPACE
GIT_USER="anjel-" /$PATH_TO_THE_SCRIPT/init-github-project.sh INIT "project-name" "short description of the project"
```
The script will ask for your Github password.
At the end you will get a local project folder and a remote Github repository.
