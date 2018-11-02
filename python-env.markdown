Python Development Environment
===============================

anything related to python dev environment, version/package management: pip/setuptools/virtualenv/easy\_install

## virtualenv

    pip install virtualenv

setup new virtual environment

    $ sudo virtualenv /opt/mypy
    [sudo] password for lee: 
    New python executable in /opt/mypy/bin/python
    Installing setuptools, pip, wheel...done.

we refer `/opt/mypy` as `ENV`, there will be `bin`, `include`, `lib`, `local` under `ENV` folder

activate a virtual env:

    source /opt/mypy/bin/activate

it will put this `ENV` in the first place of `$PATH`, and even update the shell prompt to show which env is in use

leave this virtual env with:

    deactivate

## virtualenvwrapper

    $ pip install virtualenvwrapper

    $ export WORKON_HOME=/opt/pyenvs
    $ mkdir -p $WORKON_HOME

    $ source /usr/local/bin/virtualenvwrapper.sh
    $ mkvirtualenv django
    New python executable in /opt/pyenvs/django/bin/python
    Installing setuptools, pip, wheel...done.
    virtualenvwrapper.user_scripts creating /opt/pyenvs/django/bin/predeactivate
    virtualenvwrapper.user_scripts creating /opt/pyenvs/django/bin/postdeactivate
    virtualenvwrapper.user_scripts creating /opt/pyenvs/django/bin/preactivate
    virtualenvwrapper.user_scripts creating /opt/pyenvs/django/bin/postactivate
    virtualenvwrapper.user_scripts creating /opt/pyenvs/django/bin/get_env_details

    (django) $ 

put the following lines to shell startup file `~/.bashrc`

    export WORKON_HOME=$HOME/.virtualenvs
    export PROJECT_HOME=$HOME/Devel
    source /usr/local/bin/virtualenvwrapper.sh

quick start:

- run `workon`, a list of environment is printed
- `deactivate`, exist virtualenv

install new package:

    (django) $ pip install django

list packages:

    (django) $ lssitepackages 
    django                  easy_install.py   pip                  pkg_resources  setuptools-20.2.2.dist-info  wheel-0.29.0.dist-info
    Django-1.9.4.dist-info  easy_install.pyc  pip-8.1.0.dist-info  setuptools     wheel

switch to another env:

    (django) $ workon env1
    (env1) $

commands:

    virtualenvwrapper   # list all commands
    lsvirtualenv    # list all of the envs
    allvirtualenv   # run a command in all virtualenvs
    cdvirtualenv [subdir]    # change current working directory to $VIRTUAL_ENV
    cssitepackages [subdir] # change current directory to site-packages for $VIRTUAL_ENV


projects management:

    `mkproject` Create a new virtualenv in the WORKON_HOME and project directory in PROJECT_HOME
    `cdproject` change current directory to the one specified as the project directory for the active virtualenv
    `setvirtualenvproject` bind an existing virtualenv to an existing project


