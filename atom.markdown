Atom
========

Refs: [Make Atom Your New Vim Home](http://www.blog.bdauria.com/?p=1071)

## shortcuts

	* `alt + \` focus tree view

add custom shortcuts in `keymap.cson`, for example, using `gs` to save file in vim mode:

	'atom-text-editor.vim-mode-plus:not(.insert-mode)':
	  'g s': 'core:save'

and the Surround mode is really useful:

	'atom-text-editor.vim-mode-plus:not(.insert-mode)':

		', s': 'vim-mode-plus:surround'
		', d': 'vim-mode-plus:delete-surround-any-pair'
		', D': 'vim-mode-plus:delete-surround'
		', c': 'vim-mode-plus:change-surround'
		'S': 'vim-mode-plus:surround-smart-word'

## useful packages

* `relative-numbers`
* `atom-keyboard-macros-vim`
* `platformio-ide-terminal`
	
	`ctrl + backtick` toggle the last active terminal
	`ctrl + alt + f` switch between editor and the terminal window
		
### make packages portable

https://discuss.atom.io/t/installed-packages-list-into-single-file/12227

there are two ways to make your package list portable:

* Stars

    need an account on atom.io

        apm star --installed    # star all installed packages

        apm stars --install  # install all starred packages
        

* package list

    save your package list in a file, and syncing with .dotfiles

        apm list --installed --bare > packages-list.txt                                               
    then install all packages from the list

        apm install --packages-file packages-list.txt


