Edited : 2023-09-18


# After the initial setup.

If you have not run through the initial setup yet please skip to `Goal` header.

## reloading the environment

Once you've created you virtual environment you'll be able to get back to working in fewer steps.

open a `git bash` in the agroforesty file folder.

type `git pull origin <branchName>` *replace <branchName> with the actual name of the branch.

if you forgot the branch you are working on type `git status`

This is specific important if multiple people are working on the same branch.

After ensuring the git repo is up to date, open command prompt

type `cd /d <path to you agroforesty directory>`

Once inside of the project directly type `agro-venv\Scripts\activate.bat`

If successful you will see a `(agro-venv)` to the left of you file path in command prompt.

Then type `jupyter notebook` to launch the web based editor.

*end of reloading section*


# Goal :
setup a python environment on a windows machine that allows for the execution of the sampling methodology.  

The user will be able to

- manage library installs via `pip` and a `requirements.txt`
- use `git` to access and apply version control to a code
- launch and edit a `jupyter notebook`

More information may be added to cover the sampling methodology in more detial.


# download Python
This is recommended but might not be necessary depending on your local python environment.
For this project, development will be utilizing [Python 3.11.5](https://www.python.org/downloads/)

Download the file and execute

Accept all the defaults

## test python
We will be utilizing windows command line for engaging with our python installation outside of the juypter notebook environment

type `cmd` into the windows search bar and open the `command prompt` application.

This will open a `shell` environment where you can pass specific functions directly to the computer without a specific software interface.

You command prompt will by default open in you user directly, something like `C:\Users\<your user name>`

Type the `pip` command into the `shell` and hit enter.

`pip` is a python package manager and is included in your basic python installation. If your python install was successful you should see a great deal of `commands` and `options` associated with `pip`.

*if you do not, your python installation did not complete successfully*

Type `pip install numpy`

The `numpy` package, which is used for handling vector data, will install or pip will return a message point to where the library is currently installed.

With the package installed, we can utilize the library in python.

Type `python` into the `shell` and hit enter

You will you current python version printed and the active line within shell will have changed from `C:\Users\<your user name>` to `>>>`

At this point we can only execute python code in the `shell`.

Enter the following one line at a time

`import numpy`

`a = numpy.arange(15).reshape(3, 5)``

`a`

This should return an array of number constructed using the numpy package.

`array([[ 0,  1,  2,  3,  4],
       [ 5,  6,  7,  8,  9],
       [10, 11, 12, 13, 14]])`

If you have a comparable result python is working.

We can type `quit()` to exit python and return to the shell environment.

Close the `shell`


# download Git

If you do not have it currently installed [download git](https://git-scm.com/downloads) and execute the installation file. Accept all the defaults.

## test git
`Git` is a version control software that allows you to track and manage changes to plain text files via a interface and series of commands.

We will be using `git` to share and track process on this code base using the online repository `github`.
`Github` stores stuff, `git` does the work.

After installing `git`, r ight mouse click on you desktop and select `open git bash`
This will open a `shell` environment very similar to `command prompt`. This feature is different in that it'll execute linux based commands.

`Command prompt` : engaging with python specific task

`git bash` : using git to engage in version control

We will need both of these features for the project.

With the `git bash` open type `git status` and hit enter.

you should get a message saying

`fatal: not a git repository....`

This is fine, basically there are no `git` specific files present so `git` can not do anything in this file location.

## pull repository

Got to the following [github repository](https://github.com/GeospatialCentroid/Agroforestry)

select the green `code` button and copy the url by selecting the box with two overlaping squares.

If you paste your copy data it should return

`https://github.com/GeospatialCentroid/Agroforestry.git`

Now in the git bash type the following

`git clone https://github.com/GeospatialCentroid/Agroforestry.git` and hit enter.

The windows hotkeys for copy and paste do not work inside of `git bash`. Use mouse right click and paste or cntrl + shift + v to paste your url. You can type it out as well.

Once you hit enter you will see a lot of message from git. At the end of the download you will have a new file folder called Agroforestry on you desktop.

### Repeat this process
Choose a file location that you want to store this project in and repeat the process. The nice thing about `git bash` is you can launch the `shell` from a specific file folder structure, just right click `open git bash` from the windows `file explorer` location you want the data pulled too. This can be a local or external drive.

## use command promt to navigate to your working git repo
For reference, the folder in this example is at

`C:\Users\carverd\Desktop\Agroforestry`

This will be different but regradless of where it is you will want the full path. You can grab this from the file explorer. Navigate to the folder location of you git repo and `hold shift + right click` to open up the options menu. select `copy as path` to grab the full path of the folder. *hint : this method can be used to grab the full path of files as well*

Next open your `command prompt` and type
`cd /d C:\Users\carverd\Desktop\Agroforestry` replace the path with the location on your computer.

the `cd` call is for change directory. the `/d` is to indicate that your moving to a different drive location. This may or may not be turn but it doesn't have ill effects so I've listed it here. The full path is the location that you terminal will be running out of.

Next type `dir` and hit enter.

The printed output should be a list of all files and directories within that location. You should see things like the `.gitignore` file and the `data` directory.

Because the current terminal is within this specific file folder any files that are created will be stored in the `Agroforesty` folder.   

## create a venv within repository

To isolate the development environment for this project from other python implimentations you might have on you pc we are going to create a `virtual environment` and use that to install the specific libraries we need.

Think of a `virtual environment` as a box. Thing that happen inside the box can occur within unique conditions that are not present outside of the box. It's contained.

Python comes with a `virtual environment` library preinstalled it's call `venv`.

In you terminal type

`python -m venv agro-env`

This will take some time to render but you will end up with a new file folder called `agro-env`

Using file explorer navigate into the new folder and just look at some of the objects that have been created.

## activate venv

`Virtual environments` only effect python so we will need to activate it in order to use it.

Type

`agro-env\Scripts\activate.bat`

and hit enter

If successful you will have a label `(agro-env)` on the left side of your current path in cmd line.

## install libraries into the venv
With the `virtual environment` activated, we will now install the required libraries for this project. Because we are using a `virtural environment` all these libraries will only exist inside of it. The are being install inside the container.

We will do this by utilizing a `requirements` text file that has been created through initial development proceses. This file is part of the git repo and should be in your primary agroforesty folder

type

`pip install -r requirements.txt`

and hit enter.

This is going to take a while so watch to see if it's running without errors then take a break


### Virtual environments and Git/Github
You do not want to pass your virtual environment to git because it is large and cumbersome. The requirements.txt is a short hand version that allow the virtual environment to be regenerated as needed.

You can avoid this by

1. Installing your virtual environments outside of you project folder.
2. Ensuring that the folder the virtural environment is held within is included within the `.gitignore` file.

*check to make sure the name of your virtual environment is present in the .gitignore before attempting to commit any changes to the repo*

## open the jupyter lab

Installing the libraries did a lot of work. The main change is we can now start engaging in python outside of the command prompt structure. We will be using `jupyter notebooks` for all the editing and sampling going forward.

Launch a notebook by typing

`jupyter notebook`

into the counsol and hitting enter.

Within the print out in the `shell` you will find a url starting with `http://localhost:8888`

Select this url and open it if possible.

If not copy the full line, should look something like
http://localhost:8888/tree?token=1c1eb471607ce7675a0839e2581f849c6222cd525af10c24
and paste it into a web browser.

You can now mostly ignore the `shell` and work directly in the interfrace provided within the web browser.

`Jupyter notebook` does require that the `shell` remain open in order to run so do not close it until your done working for the day.

*If you ever close your notebook in you browser tab, you can reopen as long as the `shell` is still running by typing `localhost:8888` into you browsers search.

## Managing work within jupyter notebooks

Any files that you create from the browser based interface of jupyter notebooks will be save in your local file system.

Once you complete you work for the day you will want to push you content back to github.

Close the browser page and open the `shell` that the `jupyter notebook` was running out of. Select the `shell` and type `control + c` to stop the `jupyter notebook` instance.   

It's best practice to deactivate your `virtural environment` as well with the following command.

`deactivate`

Close the shell


## Using version control to track changes
Open `git bash` by navigating to the agroforestry folder and right clicking and selecting `git bash`

First we will check the status of the changes using

`git status`

This will print what `branch` your repo is on and what files have been modified.

If files have been changed and you want to back up those files as a version on github you can continue with

`git add .`

The `.` notes that all changed files will be added. You can type out specific paths to files if you want to be more specific.

Test this by typing `git status`

This should report that the modified files (previous red text) are nor ready to be staged (green text)

Type `git commit -m'details about the changes' ` into the `git bash`. You can edit the text between the single quotes to describe what changes had been made.

Again check with `git status`

This will say changes are ahead of the origin branch and are ready to be pushed.

Do so by `git push origin branchName`

*We will discuss branching on a individual basis, just replace branchName here with the name of the branch print as part of the `git status` call from earlier

You can also check on the GitHub to see if the push was successful  

## Next Steps

More walk throughs will be provided on the sampling method. If questions arise on the set up please contact Dan at carverd@colostate.edu
