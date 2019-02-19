# Git Cheatsheet

- [Preface](#preface)
- [Basics](#basics)
  - [First Commit](#first-commit)
  - [Staging area](#staging-area)
- [Stashing](#stashing)
  - [Creating a Branch from a Stash](#creating-a-branch-from-a-stash)
- [Log](#log)
  - [limiting log output](#limiting-log-output)
  - [a GUI to visualize log](#a-gui-to-visualize-log)
  - [show log for a specific commit](#show-log-for-a-specific-commit)
- [Configs](#configs)
- [Command Aliases](#command-aliases)
- [History](#history)
- [Tags](#tags)
  - [sharing tags](#sharing-tags)
- [Undoing changes](#undoing-changes)
- [Branches](#branches)
  - [set a local branch to track a remote branch](#set-a-local-branch-to-track-a-remote-branch)
- [Remotes](#remotes)
  - [push](#push)
  - [Add a local branch that tracks a remote branch](#add-a-local-branch-that-tracks-a-remote-branch)
  - [add a remote](#add-a-remote)
  - [clone a repo to remote](#clone-a-repo-to-remote)
- [Revision Selection](#revision-selection)
  - [Commit Ranges](#commit-ranges)
- [diff](#diff)
- [checkout](#checkout)
- [rebase](#rebase)
- [ignore files](#ignore-files)
- [Hooks](#hooks)
- [Merge & Diff](#merge--diff)
- [Split a subfolder out into a new repository](#split-a-subfolder-out-into-a-new-repository)
- [Multiple accounts setup for Bitbucket/Github](#multiple-accounts-setup-for-bitbucketgithub)
- [Misc](#misc)
- [NOTICES](#notices)

## Preface

Some useful tips of git
Source:

- [Pro Git][pro_git_book]
- [GIT IMMERSION][git_immersion] easy and useful

## Basics

### First Commit

there are usually many files to add to index before first commit, it would by tedious to add them one by one, use:

    $ git add -A

### Staging area

Staging area, or index is saved in `.git/index`, git stages file as it is when you run `git add`, _if you modify a staged file, then run `git status`, the file will show as both staged and unstaged_, you can run `git add` on the file again

## Stashing

you do something to your working directory, the status is messy now, but the change is not ready for commit,
you want to switch to another branch, but you may want to go back here
use `git statsh` to save your changes

    $ git status
    # On branch master
    # Changes to be committed:
    #   (use "git reset HEAD <file>..." to unstage)
    #
    #   new file:   git.markdown
    #
    # Untracked files:
    #   (use "git add <file>..." to include in what will be committed)
    #
    #   .git.markdown.swp

    $ git stash
    Saved working directory and index state WIP on master: 06bf5ab Merge branch 'master' of ssh://guisheng.li/opt/git/guisheng.li
    HEAD is now at 06bf5ab Merge branch 'master' of ssh://guisheng.li/opt/git/guisheng.li

only staged changes and modified tracked files are saved, untracked files are still in the working directory:

    $ git status
    # On branch master
    # Untracked files:
    #   (use "git add <file>..." to include in what will be committed)
    #
    #   .git.markdown.swp
    nothing added to commit but untracked files present (use "git add" to track)

list stashes:

    $ git stash list
    stash@{0}: WIP on master: 06bf5ab Merge branch 'master' of ssh://guisheng.li/opt/git

apply stash:

    $ git stash apply
    # On branch master
    # Changes to be committed:
    #   (use "git reset HEAD <file>..." to unstage)
    #
    #   new file:   git.markdown

`git stash apply` applies the newest stash
`git stash apply stash@{2}` to specify a stash to apply

`git stash apply --index` to try to reapply the staged changes, by default `stash apply` will not restage files that are staged when you stash

stashes still exist in the stack after you apply them, remove the stashes by `git stash drop`:

    $ git stash list
    stash@{0}: WIP on master: 06bf5ab Merge branch 'master' of ssh://guisheng.li/opt/git
    $ git stash drop stash@{0}
    Dropped stash@{0} (e0f8afd65884a3343e39b4cce011b290c6d55e34)
    $ git stash list
    $

### Creating a Branch from a Stash

`git stash branch <branchname> [<stash>]`: will
creates a new branch
checkout the commit you were on when you stashed your work
reapplies your work there
drop the stash if it applies successfully

## Log

by default, `git log` will ouput all log info

`git log -p`: output diff for each commit
`git log -2`: specify how many commit info to output

`git log --stat`: for stat of each commit

customize output format with the `--pretty` option:

    $ git log --pretty=oneline -3
    14e670d8856ba12d57193327cab13d4209c16f8a modified git ref
    dc40265f0e2f6864536fd5044a0dd6487cfd47cc add back shell_commands
    2b0254c86e64d07eb20b24ad1621f920f951830f add git quickref

the more powerful `--format` option:

    $ git log -3 --format="%h %an : %s"
    14e670d Li Guisheng : modified git ref
    dc40265 Li Guisheng : add back shell_commands
    2b0254c Li Guisheng : add git quickref

some most useful format options:

    Option  Description of Output
    %H  Commit hash
    %h  Abbreviated commit hash
    %T  Tree hash
    %t  Abbreviated tree hash
    %P  Parent hashes
    %p  Abbreviated parent hashes
    %an Author name
    %ae Author e-mail
    %ad Author date (format respects the --date= option)
    %ar Author date, relative
    %cn Committer name
    %ce Committer email
    %cd Committer date
    %cr Committer date, relative
    %s  Subject

we love graphs, meet the `--graph` option:

    $ git log --format='%h : %s' --graph
    * 14e670d : modified git ref
    * dc40265 : add back shell_commands
    * 2b0254c : add git quickref
    *   06bf5ab : Merge branch 'master' of ssh://guisheng.li/opt/git/guisheng.li
    |\
    | *   dd0682a : Merge branch 'master' of guisheng.li:/opt/git/guisheng.li
    | |\
    | | * 57bca79 : added some refs for 'ls', 'touch', 'tr', etc
    | * | ef3f255 : added something about bash and shell commands
    | |/
    | * 8f6f5e9 : shell commands ref changes

a list of useful options for `git log`:

    Option  Description
    -p  Show the patch introduced with each commit.
    --word-diff Show the patch in a word diff format.
    --stat  Show statistics for files modified in each commit.
    --shortstat Display only the changed/insertions/deletions line from the --stat command.
    --name-only Show the list of files modified after the commit information.
    --name-status   Show the list of files affected with added/modified/deleted information as well.
    --abbrev-commit Show only the first few characters of the SHA-1 checksum instead of all 40.
    --relative-date Display the date in a relative format (for example, “2 weeks ago”) instead of using the full date format.
    --graph Display an ASCII graph of the branch and merge history beside the log output.
    --pretty    Show commits in an alternate format. Options include oneline, short, full, fuller, and format (where you specify your own format).
    --oneline   A convenience option short for `--pretty=oneline --abbrev-commit`.

### limiting log output

    $ git log --since=2.day --oneline
    14e670d modified git ref
    dc40265 add back shell_commands
    2b0254c add git quickref
    06bf5ab Merge branch 'master' of ssh://guisheng.li/opt/git/guisheng.li
    2a1722b added sql cheatsheet, modified vim

`--author`: specify author
`--committer`: specify committer
`--grep`: limit to commits whose comment can by matched

    $ git log --grep='.*vim' --since='1.week' --oneline
    2a1722b added sql cheatsheet, modified vim

### a GUI to visualize log

use `gitk`, it accepts nearly all options for `git log`

    $ gitk --since='1.month'

### show log for a specific commit

    $ git show <commit>  # show diff introduced by <commit>
    $ git show <commit> --name-status   # show only names of files changed in <commit>

    $ git diff <commit>^! --name-status  # basically the same, <commit>^! means <commit>^..<commit>

## Configs

configuration levels:

- `--system`: `/etc/gitconfig`
- `--global`: `~/.gitconfig`
- `--local`: `$PROJECT/.git/config`
- `--file <filename>`

```sh
# list configs
$ git config --global -l

# get config
$ git config --global user.name
Gary Li

# set config
$ git config --global core.safecrlf true
```

quite useful configs:

    core.editor
    user.name
    user.email
    commit.template     # a path to a file containing commit message template
    core.excludesfile   # can be set to a global .gitignore file
    color.ui            # turn on all the default terminal coloring

whitespace, line-endings:

- `core.autocrlf`

  - `true` # convert cflf to lf on commit, vice versa on checkout
  - `input` # convert cflf to lf on commit, do nothing on checkout, suitable for Linux users
  - `false` # nothing is done on commit or checkout

- `core.whitespace`
  - `trailing-space,space-before-tab,-indent-with-non-tab,-cr-at-eol` # default value, git will mark whitespace issues with special colors when diff files

set customized color to output:

    $ git config --global color.diff.meta "blue black bold"

## Command Aliases

add aliases to `~/.gitconfig`, these really helps to make your git life much more easier

    [alias]
      co = checkout
      ci = commit
      st = status
      br = branch
      l = log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short
      type = cat-file -t
      dump = cat-file -p

## History

go back to a history version:

    $ git checkout <hash>

when you go to a history version, you are in 'detached HEAD' state, if you want to save the changes you made in this state, create a new branch:

    $ git checkout -b <branch_name>

## Tags

list tags

    $ git tag
    v1
    v1-beta

    # checkout to a tag
    $ git checkout v1
    HEAD is now at 9b28e32... add a comment line

    # add a tag
    $ git tag v2

    $ git tag
    v1
    v1-beta
    v2

    # tags showed in log
    $ git l
    * 9b28e32 2013-06-01 | add a comment line (HEAD, v2, v1, master)
    * c5be8c4 2013-06-01 | add a default value (v1-beta)
    * 6a5a3a2 2013-06-01 | Using ARGV
    * 7ec63cb 2013-06-01 | First commit

    # delete a tag
    $ git tag -d v2
    Deleted tag 'v2' (was 9b28e32)

    $ git l
    * 9b28e32 2013-06-01 | add a comment line (HEAD, v1, master)
    * c5be8c4 2013-06-01 | add a default value (v1-beta)
    * 6a5a3a2 2013-06-01 | Using ARGV
    * 7ec63cb 2013-06-01 | First commit

### sharing tags

by default, `git push` doesn't transfer tags to remote server, you need do that explicitly:

    $ git push origin <tagname>
    $ git push origin --tags    # push all the tags

## Undoing changes

amend last commit:

    $ git commit --amend

revert a commit, will create a new commit reverting changes introduced in that commit:

    $ git revert <commit>       # creating a new commit reverting changes introduced by <commit>

reset to a specific commit by `git reset`:

    $ git l
    * d249bad 2013-06-01 | Revert "we didn't want this commit" (HEAD, oops, master)
    * 0cbff24 2013-06-01 | we didn't want this commit
    * 9b28e32 2013-06-01 | add a comment line (v1)
    * c5be8c4 2013-06-01 | add a default value (v1-beta)
    * 6a5a3a2 2013-06-01 | Using ARGV
    * 7ec63cb 2013-06-01 | First commit

    $ git reset --hard v1 # "--hard" updates the working directory
    HEAD is now at 9b28e32 add a comment line

    $ git l
    * 9b28e32 2013-06-01 | add a comment line (HEAD, v1, master)
    * c5be8c4 2013-06-01 | add a default value (v1-beta)
    * 6a5a3a2 2013-06-01 | Using ARGV
    * 7ec63cb 2013-06-01 | First commit

    # the commits are not lost, they are still in the repo, use --all to show
    $ git l --all
    * d249bad 2013-06-01 | Revert "we didn't want this commit" (oops)
    * 0cbff24 2013-06-01 | we didn't want this commit
    * 9b28e32 2013-06-01 | add a comment line (HEAD, v1, master)
    * c5be8c4 2013-06-01 | add a default value (v1-beta)
    * 6a5a3a2 2013-06-01 | Using ARGV
    | * 12ac967 2013-06-01 | commit in DETACHED HEAD mode (b2)
    |/
    * 7ec63cb 2013-06-01 | First commit

    # remove the oops tag
    $ git tag -d oops
    Deleted tag 'oops' (was d249bad)

    # after the tag is deleted, the resetted commits are deleted
    $ git l --all
    * 12ac967 2013-06-01 | commit in DETACHED HEAD mode (b2)
    | * 9b28e32 2013-06-01 | add a comment line (HEAD, v1, master)
    | * c5be8c4 2013-06-01 | add a default value (v1-beta)
    | * 6a5a3a2 2013-06-01 | Using ARGV
    |/
    * 7ec63cb 2013-06-01 | First commit

`--all` makes us to see all the branches

_DO NOT USE RESET ON A SHARED BRANCH_

## Branches

create a branch, and switch to that branch, `git checkout -b <new_branch_name>`:

    $ git checkout -b greet
    Switched to a new branch 'greet'

switch branches, `git checkout <branch>`:

    $ git b
    * greet
      master

    $ git checkout master
    Switched to branch 'master'

    $ git b
      greet
    * master

show all branches(local and remote) use `git branch -a`:

    $ git branch -a
    * master
      remotes/origin/HEAD -> origin/master
      remotes/origin/greet
      remotes/origin/master

show verbose info about branches:

    $ git branch -a -vv
    * master                16ab339 [origin/master] add js
      remotes/origin/master 16ab339 add js

show branches already merged in current branch, they point to an ancestor commit of current branch:

    $ git branch --merged

show branches not merged in current branch, thest branch diverged from current branch:

    $ git branch --no-merged

local branches do not automatically synchronize to remotes, you have to explicitly push the branches you want to share

```bash
# git push <remote> <branch>[:<remote-branch>]
# use '-u' to set the remote branch as upstream

git push -u origin test     # push local branch 'test' to origin
git push -u origin test:abc # push local branch 'test' to origin as branch 'abc'
```

delete a remote branch

```bash
git push origin :hotfix  # delete the 'hotfix' branch on origin
```

### set a local branch to track a remote branch

```bash
# set upstream to a remote branch
git branch --set-upstream-to=bb/master

# create a new branch on local and tracking a remote one
git branch --track testing origin/testing
```

## Remotes

show remotes:

    $ git remote    # list remotes
    origin

show detailed info about remotes, which branch you have tracked, what will be done when you run `git pull` or `git push`

    $ git remote show origin
    * remote origin
      Fetch URL: /home/lee/code/hello
      Push  URL: /home/lee/code/hello
      HEAD branch (remote HEAD is ambiguous, may be one of the following):
        greet
        master
      Remote branches:
        greet  tracked
        master tracked
      Local branch configured for 'git pull':
        master merges with remote master
      Local ref configured for 'git push':
        master pushes to master (up to date)

fetch remote commits:

`git fetch` will fetch remote commits, but it will not merge them locally, you can do that manually by `git merge origin/master`

or, use `git pull`, which fetch remote commits and merge them locally in one step

### push

    # push to the 'master' branch on the 'shared' remote
    $ git push shared master

### Add a local branch that tracks a remote branch

    $ git branch -a
    * master
      remotes/origin/HEAD -> origin/master
      remotes/origin/greet
      remotes/origin/master

remote origin has a 'greet' branch, but you do not have it locally, you can checkout the remote branch:

    $ git checkout greet    # a local branch 'greet' will now track 'origin/greet'

or, you can add a local 'greet' branch to track the remote one:

    $ git branch --track greet origin/greet
    Branch greet set up to track remote branch greet from origin.
    $ git branch -a
      greet
    * master
      remotes/origin/HEAD -> origin/master
      remotes/origin/greet
      remotes/origin/master

### add a remote

    $ git remote -v
    $ git remote add shared ../hello.git
    $ git remote -v
    shared  ../hello.git (fetch)
    shared  ../hello.git (push)

### clone a repo to remote

    $ git clone --bare git-demo/ git-demo-remote
    $ cd git-demo
    $ git remote add origin ../git-demo-remote/

## Revision Selection

you can reference a single revision by commit hash, branch name, or reflog shortname

`git reflog` shows where your HEAD have been, you can select a revision by `HEAD@{n}` or `master@{n}`

    $ git reflog
    f7c958f HEAD@{0}: commit: various modifications
    f9ddb8b HEAD@{1}: commit: add vimperator and super_user_tips refs
    2c04075 HEAD@{2}: commit: add sth to svn ref
    ...

- `@{<n>}`

  reflog entry of current branch

- `@{-<n>}`

  `<n>`th branch checked out before the current one

- `<refname>@{upstream}`,`<refname>@{u}`

  the branch the ref is set to build on top of

- `<rev>^{<type>}`

  `<rev>` could be a tag, dereference the tag recursively until an object of the `<type>` is found

- `<rev>^{/<text>}`

  `HEAD^{/fix nasty bug}`, youngest matching commit reachable from `<rev>`

- `:/<text>`

  `:/fix nasty bug`, youngest matching commit reachable from any ref

- `<rev>:<path>`

  `HEAD:./hello.php`, blob or tree at the given path in `<rev>`
  `:./hello.php`, content recorded **in the index** at the given path

* `HEAD^1`, `HEAD^` the first parent of HEAD
* `HEAD^2` the second parent of HEAD, only useful for merge commits, which have more than one parent, the first is the one you were on when you merged, the second is the commit you merged in
* `HEAD~` the first parent of HEAD, equivalent to `HEAD^`
* `HEAD~2` the first parent of first parent of HEAD, can also be written as `HEAD^^`

select a ref by time:

    $ git show master@{yesterday}
    $ git show master@{3.month}

`master@{3.month}`, `master@{3.months}`, `master@{3 months ago}` are the equivalent, _these reflogs are local, you maynot use them for commits older than a few months_

- `HEAD` the commit on which you based the changes in the working tree
- `MERGE_HEAD` the commit which you are merging into your branch when you run git merge
- `CHERRY_PICK_HEAD` the commit which you are cherry-picking when you run git cherry-pick

### Commit Ranges

some commands traversing commit history, such as `git log`, if you specify a signle revision for these commands, they will traversing from that single commit to all of its ancestors.

get commits reachable from r2, but not reachable from r1, use these, they are equivalent:

    $ git log ^r1 r2
    $ git log r1..r2

    $ git log origin..HEAD # what did i do since forked from origin
    $ git log HEAD..origin # what did origin do since I forked from it

triple dot notation:

    $ git log r1...r2   # commits reachable from either r1 or r2 but not from both

other notations:

    r1^@    # any commits reachable from r1, but not r1 itself
    r1^!    # just r1, exclude all of its parents

## diff

    $ git diff [path]                       # diff working tree with index (staging area)
    $ git diff <commit> [path]              # diff working tree with <commit>
    $ git diff --cached <commit> [path]     # diff staging area with <commit>

    $ git diff --color @{3days}..HEAD -- [path]     # diff path in commits 3 days ago and now with color

## checkout

    $ git checkout <commit> -- <path>       # checkout a file from a commit to working directory

## rebase

typical usage: moving a topic branch to a new base

```
      A---B---C topic
     /
D---E---F---G master
```

```bash
git rebase master
git rebase master topic
```

this will result in

```
               A'--B'--C' topic
             /
D---E---F---G master
```

You can also use it to **reorder, squash, edit and split commits**, see `git help rebase` for details:

```
git rebase -i HEAD~5
```

## ignore files

global ignore files, `~/.gitignore`, then make it a global ignore file with:

    $ git config --global core.excludesfile ~/.gitignore

local ignore files, `$PROJECT/.gitignore`, `$PROJECT/info/exclude`

ignore an already tracked file, remove them from the index, and add them to .gitignore:

    $ git rm --cached <file> ...

## Hooks

git hooks are scripts stored in the `.git/hooks/` directory, they are fired when paticular events happen, if they exists with non-zero status code, the event may be stopped.

there are two types: client-side hooks and server-side hooks

- client-side:

  - `pre-commit`

    called by `git commit` without any arguments, before you type any commit message, can be used to verify what is about to be committed, such as lint the code, check TODOs

  - `prepare-commit-msg`

    run before the commit message editor is fired up but after the default message is created, lets you edit default commit message; generally isn't useful for normal commits, good for commits where default commit message is auto-generated, such as templated commit messages, merge commits, squashed commits, and amended commits. You may use it in conjunction with a commit template to programmatically insert information.

  - `commit-msg`

    takes one parameter, the path to the file contains current commit message, can be used to validate commit message

  - `post-commit`

    fires after the commit process is completed

  - `pre-rebase`
  - `post-checkout`
  - `post-merge`

- server-side:

  - `pre-receive`

    check commit message, check premissions, etc, can stop the push operation

  - `post-receive`

    notify users, emails, etc

  - `update`

    similar to `pre-receive`, but runs for each branch that is pushed to

## Merge & Diff

use merge tool to resolve conflicts:

    $ git mergetool

diff and merge configs:

    merge.tool
    diff.external

## Split a subfolder out into a new repository

looks like there are two ways to accomplish this:

`git subtree split` and `git filter-branch`

[Splitting a subfolder out into a new repository](https://help.github.com/articles/splitting-a-subfolder-out-into-a-new-repository/)

[Using Git subtrees for repository separation](https://makingsoftware.wordpress.com/2013/02/16/using-git-subtrees-for-repository-separation/)

[Stackoverflow: Detach (move) subdirectory into separate Git repository](http://stackoverflow.com/questions/359424/detach-move-subdirectory-into-separate-git-repository)

    # create a new repo and add remote
    mkdir newrepo
    cd newrepo/
    git init --bare
    git remote add origin git@bitbucket.org:XXXX/newrepo.git

    # split the subfolder out as a new branch, and then push it to the new repo
    cd ../oldrepo
    git subtree split --prefix=path/to/subfolder -b split
    git push ../newrepo/ split:master
    cd ../newrepo/
    git push origin master

## Multiple accounts setup for Bitbucket/Github

[Mutiple accounts and ssh keys](http://dbushell.com/2013/01/27/multiple-accounts-and-ssh-keys/)

create ssh keys:

    cd ~/.ssh
    ssh-keygen -t rsa -f gary-new -C "gary@example.com"

in `.ssh/config`

    Host bitbucket.org
      User git
      Hostname bitbucket.org
      PreferredAuthentications publickey
      IdentityFile ~/.ssh/id_rsa

    Host bitbucket-accountB
      User git
      Hostname bitbucket.org
      PreferredAuthentications publickey
      IdentitiesOnly yes
      IdentityFile ~/.ssh/accountB

## Misc

- `git status` may output Chinese characters in wrong encoding, fix:

  ```bash
  git config --global core.quotepath false
  ```

- ignore changes in tracked file:

  ```bash
  git update-index --assume-unchanged <file>
  ```

- create a bare repo 'hello.git' based on 'hello'

  ```bash
  git clone --bare hello hello.git
  ```

- add files interactively

  ```bash
  git add -i
  ```

- stage part of a file (you can select which change you want to stage):

  ```bash
  git add --patch
  git add -p    # the same
  ```

- add all modified files

  ```bash
  git add -u    # --update
  ```

## NOTICES

**DO NOT USE REBASE ON SHARED BRANCHES**

[pro_git_book]: http://git-scm.com/book
[git_immersion]: http://gitimmersion.com/index.html
