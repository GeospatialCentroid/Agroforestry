Edited : 2023-09-18

# Goal :
setup a python environment on a windows machine that allows for the execution of the sampling methodology.  

The user will be able to

- manage library installs via `pip` and a `requirements.txt`
- use `git` to access and apply version control to a code
- launch and edit a `jupyter notebook`
- authenticate `google earth engine`

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


## create a venv within repository

## activate venv

## install libraries into the venv



## open the jupyter lab
