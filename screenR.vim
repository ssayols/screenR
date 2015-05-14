
if $TERM !~ "screen"
    call RWarningMsgInp("Not inside GNU Screen! You have to start screen before starting Vim.")
    finish
endif

if !exists("g:screenR_rh")
    let g:screenR_height = 15
endif

function! StartR(whatr)
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
        return
    endif
	
	"
	"stuff added from global.vim (StartR())
	"
    if has("gui_macvim") && v:servername != ""
        let $VIMEDITOR_SVRNM = "MacVim_" . v:servername
        let $VIM_BINARY_PATH = substitute($VIMRUNTIME, "/MacVim.app/Contents/.*", "", "") . "/MacVim.app/Contents/MacOS/Vim"
    elseif !has("clientserver")
        let $VIMEDITOR_SVRNM = "NoClientServer"
    elseif v:servername == ""
        let $VIMEDITOR_SVRNM = "NoServerName"
    else
        let $VIMEDITOR_SVRNM = v:servername
    endif

    call writefile([], g:rplugin_tmpdir . "/globenv_" . $VIMINSTANCEID)
    call writefile([], g:rplugin_tmpdir . "/liblist_" . $VIMINSTANCEID)
    call delete(g:rplugin_tmpdir . "/libnames_" . $VIMINSTANCEID)

	let start_options = ['options(vimcom.verbose = 1)']
    if g:vimrplugin_objbr_opendf
        let start_options = ['options(vimcom.opendf = TRUE)']
    else
        let start_options = ['options(vimcom.opendf = FALSE)']
    endif
    if g:vimrplugin_objbr_openlist
        let start_options += ['options(vimcom.openlist = TRUE)']
    else
        let start_options += ['options(vimcom.openlist = FALSE)']
    endif
    if g:vimrplugin_objbr_allnames
        let start_options += ['options(vimcom.allnames = TRUE)']
    else
        let start_options += ['options(vimcom.allnames = FALSE)']
    endif
    if g:vimrplugin_texerr
        let start_options += ['options(vimcom.texerrs = TRUE)']
    else
        let start_options += ['options(vimcom.texerrs = FALSE)']
    endif
    if g:vimrplugin_objbr_labelerr
        let start_options += ['options(vimcom.labelerr = TRUE)']
    else
        let start_options += ['options(vimcom.labelerr = FALSE)']
    endif
    if g:vimrplugin_vimpager == "no" || !has("clientserver") || v:servername == ""
        let start_options += ['options(vimcom.vimpager = FALSE)']
    else
        let start_options += ['options(vimcom.vimpager = TRUE)']
    endif
    let start_options += ['if(utils::packageVersion("vimcom") != "1.2.5") warning("Your version of Vim-R-plugin requires vimcom-1.2-5.", call. = FALSE)']

    let rwd = ""
    if g:vimrplugin_vim_wd == 0
        let rwd = expand("%:p:h")
    elseif g:vimrplugin_vim_wd == 1
        let rwd = getcwd()
    endif
    if rwd != ""
        if has("win32") || has("win64")
            let rwd = substitute(rwd, '\\', '/', 'g')
        endif
        let start_options += ['setwd("' . rwd . '")']
    endif
    call writefile(start_options, g:rplugin_tmpdir . "/start_options.R")

    if !exists("g:vimrplugin_r_args")
        let b:rplugin_r_args = " "
    else
        let b:rplugin_r_args = g:vimrplugin_r_args
    endif

    if a:whatr =~ "custom"
        call inputsave()
        let b:rplugin_r_args = input('Enter parameters for R: ')
        call inputrestore()
    endif

    if g:vimrplugin_applescript
        call StartR_OSX()
        return
    endif

    if has("win32") || has("win64")
        call StartR_Windows()
        return
    endif

    " R was already started. Should restart it or warn?
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
		if g:vimrplugin_restart
			call RQuit("restartR")
			call ResetVimComPort()
		endif
    endif

    if b:rplugin_r_args == " "
        let rcmd = g:rplugin_R
    else
        let rcmd = g:rplugin_R . " " . b:rplugin_r_args
    endif
	"
	"end of stuff
	"
    let slog = system('screen -X eval "split" "focus down" "resize ' . 
                \ g:screenR_height . '" "screen -t RConsole" ')
    let slog = system("screen -p RConsole -X stuff '" .
                \ "VIMRPLUGIN_TMPDIR=" . g:rplugin_tmpdir .
                \ " VIMRPLUGIN_COMPLDIR=" . substitute(g:rplugin_compldir, ' ', '\\ ', "g") .
                \ " VIMINSTANCEID=" . $VIMINSTANCEID . 
                \ " VIMRPLUGIN_SECRET=" . $VIMRPLUGIN_SECRET . 
                \ " VIMEDITOR_SVRNM=" . $VIMEDITOR_SVRNM . " R'\<c-m>")
    let g:SendCmdToR = function('SendCmdToR_GNUScreen')

	"
	"stuff added from global.vim (StartR_TmuxSplit())
	"
    if g:vimrplugin_restart
        sleep 200m
        let ca_ck = g:vimrplugin_ca_ck
        let g:vimrplugin_ca_ck = 0
        call g:SendCmdToR(rcmd)
        let g:vimrplugin_ca_ck = ca_ck
    endif
    let g:rplugin_last_rcmd = rcmd
    if WaitVimComStart()
        call SendToVimCom("\005B Update OB [StartR]")
        if g:vimrplugin_after_start != ''
            call system(g:vimrplugin_after_start)
        endif
    endif
	"
	"end of stuff
	"

endfunction

function! SendCmdToR_GNUScreen(cmd)
    if g:vimrplugin_ca_ck
        let cmd = "\001" . "\013" . a:cmd
    else
        let cmd = a:cmd
    endif

    let str = substitute(cmd, "\\", "\\\\\\\\", "g")
    let str = substitute(str, "\\^", "\\\\^", "g")
    let str = substitute(str, "\\$", "\\\\$", "g")
    let str = substitute(str, "'", "'\\\\''", "g")
    let scmd = "screen -p RConsole -X stuff '" . str . "\<C-M>'"
    let rlog = system(scmd)
    if v:shell_error
        let rlog = substitute(rlog, "\n", " ", "g")
        let rlog = substitute(rlog, "\r", " ", "g")
        call RWarningMsg(rlog)
        let g:SendCmdToR = function('SendCmdToR_fake')
        return 0
    endif
    return 1
endfunction
