screenR
=======

Allow the Vim-R-plugin to use GNU Screen to send commands to R

This script provides limited support to GNU Screen for users that
cannot use Tmux. Please, fork and improve it. The Vim-R-plugin is
available at:

    http://www.vim.org/scripts/script.php?script_id=2628


Configuration
=============

Put in your vimrc:

    let vimrplugin_source = "/path/to/screenR.vim"


If you are going to use Vim in an environment where X is running,
put in your bashrc:

    alias vim='vim --servername VIM'


Usage
=====

    1. Start screen.
    2. Start editing an R script with Vim.
    3. Use the Vim-R-plugin as usual.

