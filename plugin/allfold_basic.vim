" -------------------------------------
" allfold_basic.vim - Version: beta 0.8
" -------------------------------------
"
" VIM script to display all selected lines with others hidden in closed folds
" Basic functionality.  Also required for extra features in allfold_full.vim
"
" Last Change: 2003-02-26
" Written By: Marion W. Berryman  mwberryman-at-copper-dot-net
"
"
" WARNING! These functions erase all manual folds within a file before
"          setting up their own manual folding scheme!!!
"       
"=============================================================================
"                            Allfold Vim Script
"=============================================================================
"
"=============================================================================
"                           Script Initialization
"=============================================================================
"
if exists("g:AFB_allfold_disabled")
	if g:AFB_allfold_disabled | finish | endif
endif

if exists("g:AFB_loaded")
	finish
endif

"
" Initialize buffer global variables.
"
function! s:AFB_setup()
if !exists( "b:af_done" )
	let b:af_done = 0
	let b:kx_map=''
	let b:kx_map_2=''
	let b:cmd_done_list=''
	let b:cmds_after_init_map=0   " Count of AFP, AFB, and AFI commands
                                 " since the map was last initialized
endif
endf

"
" Initialize VIM global variables.
"
let g:AFB_loaded=1
let g:AFB_map_exclude = "0"
let g:AFB_map_keep = "1"
let g:AFB_map_special = "9"
let g:AFB_vcmd_sep = "\n"
let g:AFB_vcmd_sep_match='\n'

"=============================================================================
"                 Marking and Folding Primitive Operations
"=============================================================================
"
"-----------------------------------------------------------------------------
" Update kx_map for lines to be included in display that match pattern.
" Arguments: pattern - Pattern to match for start of blocks.
"            before  - Additional number of lines before blocks.
"            after   - Additional number of lines after blocks.
" Returns: Boolean indicating if startline was folded out of view.
"
function! AFB_markmap_pattern(pattern,before,after)
	normal zE
	normal 1G0
	let lastline=line("$")
	while search(a:pattern, "W") > 0
		let fl=line(".")
		normal 0
		let rb=fl-a:before-1
		if (rb<0) | let rb=0 | endif
		let ra=fl+a:after-1
		if (ra>lastline-1) | let ra=lastline-1 | endif
		call AFB_update_map(rb,ra,g:AFB_map_keep)
		exe "normal ".fl."G$"
		if fl==lastline | break | endif
	endwhile
endfunction

"-----------------------------------------------------------------------------
" Update kx_map for lines to be included in display for blocks.
" Arguments: start_pattern - Pattern to match for start of blocks.
"            end_pattern   - Pattern to match for end of blocks.
"            before        - Additional number of lines before blocks.
"            after         - Additional number of lines after blocks.
" Returns: Boolean indicating if startline was folded out of view.
"
function! AFB_markmap_block(start_pattern,end_pattern,before,after)
	normal zE
	normal 1G0
	let lastline=line("$")
	let lastline0=lastline-1
	while search(a:start_pattern, "W") > 0
		let sl=line(".")
		if sl==lastline | break | endif
		normal j0
		let end_found=0
		let el=search(a:end_pattern, "W")
		if (! el) | break | endif
		let rb=sl-a:before-1
		if (rb<0) | let rb=0 | endif
		let ra=el+a:after-1
		if (ra>lastline0) | let ra=lastline0 | endif
		call AFB_update_map(rb,ra,g:AFB_map_keep)
		exe "normal ".el."G$"
		if el==lastline | break | endif
	endwhile
endfunction

"-----------------------------------------------------------------------------
" Fold the file to display desired lines marked in the markmap string.
" Arguments: startline - Current line at start of operation.
" Returns: Boolean indicating if startline was folded out of view.
"
function! AFB_fold_markmap(startline,cmdopts)
	if (! b:af_done)
		let b:save_foldlevel=&foldlevel
		set foldmethod=manual
	endif
	normal 1G0
	normal zE
	let sl_dec=a:startline-1
	let startline_folded=0
	let startmatching=0
	let startfold=0
	while (1)
	 	let startfold=match(b:kx_map,g:AFB_map_exclude,startmatching)
		if startfold <0 | break | endif
	 	let endfold=match(b:kx_map,g:AFB_map_keep,startfold)
		if endfold < 0 
			let endfold=strlen(b:kx_map)-1
		else
			let endfold=endfold-1
		endif
		exe (startfold+1).",".(endfold+1)."fold"
		if ((sl_dec>=startfold)&&(sl_dec<=endfold))
			let startline_folded=1
		endif
		let startmatching=endfold+1
		if startmatching>(strlen(b:kx_map)-1) | break | endif
	endwhile
	return startline_folded
endfunction

"-----------------------------------------------------------------------------
" Initialize a map of lines to control fold display.
" Arguments: nbrlines - Number of lines to be mapped.
"            iv       - Initial value for map entries.
" Returns: nothing
"
function! AFB_init_kxmap(nbrlines,iv)
	let kx_str='00000000000000000000000000000000000000000000000000'
	if a:iv != '0' | let kx_str=substitute(kx_str,'0',a:iv,'g') | endif
   let kx_str=kx_str.kx_str
	let kx_str=kx_str.kx_str
	let nbr_kx_str=a:nbrlines/strlen(kx_str)
	let b:kx_map=''
	let ix=1
	while (ix<=nbr_kx_str)
		let b:kx_map=b:kx_map.kx_str
		let ix=ix+1
	endwhile
	let b:kx_map=b:kx_map.strpart(kx_str,0,a:nbrlines%strlen(kx_str))
	let b:cmds_after_init_map=0
	return
endfunction

"-----------------------------------------------------------------------------
" Logically invert the kx_map
" Arguments: none
" Returns: nothing
"
function! AFB_not_map()
	let b:kx_map=substitute(b:kx_map,g:AFB_map_exclude,g:AFB_map_special,"g")
	let b:kx_map=substitute(b:kx_map,g:AFB_map_keep,g:AFB_map_exclude,"g")
	let b:kx_map=substitute(b:kx_map,g:AFB_map_special,g:AFB_map_keep,"g")
endfunction

"-----------------------------------------------------------------------------
" Or together the overall kx_map with the map for the last command kx_map_2.
" Arguments: none
" Returns: nothing
"
function! AFB_or_maps()
	let startmatching=0
	while (1)
	 	let found_keep=match(b:kx_map_2,g:AFB_map_keep,startmatching)
		if found_keep <0 | break | endif
	 	let found_exclude=match(b:kx_map_2,g:AFB_map_exclude,found_keep)
		if found_exclude < 0 
			let found_exclude=strlen(b:kx_map_2)-1
		else
			let found_exclude=found_exclude-1
		endif
		call AFB_update_map(found_keep,found_exclude,g:AFB_map_keep)
		let startmatching=found_exclude+1
		if startmatching>(strlen(b:kx_map_2)-1) | break | endif
	endwhile
endfunction

"-----------------------------------------------------------------------------
" And together the overall kx_map with the map for the last command kx_map_2.
" Arguments: none
" Returns: nothing
"
function! AFB_and_maps()
	let startmatching=0
	while (1)
	 	let found_exclude=match(b:kx_map_2,g:AFB_map_exclude,startmatching)
		if found_exclude <0 | break | endif
	 	let found_keep=match(b:kx_map_2,g:AFB_map_keep,found_exclude)
		if found_keep < 0 
			let found_keep=strlen(b:kx_map_2)-1
		else
			let found_keep=found_keep-1
		endif
		call AFB_update_map(found_exclude,found_keep,g:AFB_map_exclude)
		let startmatching=found_keep+1
		if startmatching>(strlen(b:kx_map_2)-1) | break | endif
	endwhile
endfunction

"-----------------------------------------------------------------------------
" Update a portion of the kx_map to a keep/exclude value.
" Arguments: firstpos - First position in kx_map to update.
"            lastpos  - Last position in kx_map to update.
"            markchar - Character used to mark map for update.
" Returns: nothing
"
function! AFB_update_map(firstpos,lastpos,markchar)
	let length=a:lastpos-a:firstpos+1
	let str_ks=strpart(b:kx_map,0,length)
	let str_ks=substitute(str_ks,'.',a:markchar,'g')
	if a:firstpos==0
		let map_pat='^\zs.\{'.length.'}'
	else
		let map_pat='^.\{'.a:firstpos.'}\zs.\{'.length.'}'
	endif
	let b:kx_map=substitute(b:kx_map,map_pat,str_ks,'')
endfunction

"=============================================================================
"                      Command Implemenation Functions
"=============================================================================
"
"-----------------------------------------------------------------------------
" Do the all fold fold marking and then fold the buffer
" Arguments: List of command arguments.
"     1. Command options. (Optional)
"		2. Pattern to match for lines to be display and not folded
"		3. Number of additonal lines to display before matching lines
"		4. Number of additonal lines to display after matching lines
"     Arguments 3 and 4 are optional and if not provided are
"		assumed to be 0.
" Returns: nothing
"
function! AFB_fold_pattern(...)
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let pattern=''
	let before=''
	let after=''
	let cmdopts=''
	let ix=0
	while ix < a:0
		let ix=ix+1
		let val=a:{ix}
		if ix==1 && val[0]=='-' | let cmdopts=val | continue | endif
		if pattern=='' | let pattern=val | continue | endif
		if before=='' | let before=val | continue | endif
		if after=='' | let after=val | continue | endif
	endwhile
	if pattern==''
		echoh Error|ec "No pattern for all fold pattern"|echoh None
		return
	endif
	if before=='' | let before=0 | endif
	if after=='' | let after=0 | endif

	let startline=line(".")
	call AFB_premark('AFP',cmdopts)
	call AFB_markmap_pattern(pattern,before,after)
	call AFB_postmark('AFP',cmdopts)
	let b:cmds_after_init_map=b:cmds_after_init_map+1
	if (match(cmdopts,"-list")>=0)
		return
	endif
	let cmdstr='AFP ' 
	if cmdopts!=''
		let cmdstr=cmdstr.cmdopts.' '
	endif
	let pattern=substitute(pattern," ",'\\ ',"g")
	let cmdstr=cmdstr.pattern.' '.before.' '.after
	call AFB_finish_newcmd(startline,cmdopts,cmdstr)
	echo "Folding for pattern done"
	return
endfunction

"-----------------------------------------------------------------------------
" Fold all blocks defined by start and end patterns
" Arguments: List of command arguments.
"     1. Command options. (Optional)
"		2. Pattern to match for beginning of block.
"		3. Pattern to match for end of block.
"		4. Number of additonal lines to display before blocks.
"		5. Number of additonal lines to display after blocks.
"     Arguments 4 and 5 are optional and if not provided are
"		assumed to be 0.
" Returns: nothing
"
function! AFB_fold_blocks(...)
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let start_pattern=''
	let end_pattern=''
	let before=''
	let after=''
	let cmdopts=''
	let ix=0
	while ix < a:0
		let ix=ix+1
		let val=a:{ix}
		if ix==1 && val[0]=='-' | let cmdopts=val | continue | endif
		if start_pattern=='' | let start_pattern=val | continue | endif
		if end_pattern=='' | let end_pattern=val | continue | endif
		if before=='' | let before=val | continue | endif
		if after=='' | let after=val | continue | endif
	endwhile
	if start_pattern==''
		echoh Error|ec "No start pattern for all fold block"|echoh None
		return
	endif
	if end_pattern==''
		echoh Error|ec "No end pattern for all fold block"|echoh None
		return
	endif
	if before=='' | let before=0 | endif
	if after=='' | let after=0 | endif
	let startline=line(".")
	call AFB_premark('AFB',cmdopts)
	call AFB_markmap_block(start_pattern,end_pattern,before,after)
	call AFB_postmark('AFB',cmdopts)
	let b:cmds_after_init_map=b:cmds_after_init_map+1
	if (match(cmdopts,"-list")>=0)
		return
	endif
	let cmdstr='AFB ' 
	if cmdopts!=''
		let cmdstr=cmdstr.cmdopts.' '
	endif
	let start_pattern=substitute(start_pattern," ",'\\ ',"g")
	let end_pattern=substitute(end_pattern," ",'\\ ',"g")
	let cmdstr=cmdstr.start_pattern.' '.end_pattern.' '.before.' '.after
	call AFB_finish_newcmd(startline,cmdopts,cmdstr)
	echo "Folding for blocks done"
endfunction

"-----------------------------------------------------------------------------
" Invert logic of kx_map and display resutls.
" Arguments: none
" Returns: nothing
"
function! AFB_invert(...)
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let cmdopts=''
	let ix=0
	while ix < a:0
		let ix=ix+1
		let val=a:{ix}
		if ix==1 && val[0]=='-' | let cmdopts=val | continue | endif
	endwhile
	let startline=line(".")
	call AFB_premark('AFI',cmdopts)
	if b:cmds_after_init_map>0
		call AFB_not_map()
	endif
	let b:cmds_after_init_map=b:cmds_after_init_map+1
	if (match(cmdopts,"-list")>=0)
		return
	endif
	let cmdstr='AFI' 
	if cmdopts!=''
		let cmdstr=cmdstr.' '.cmdopts
	endif
	call AFB_finish_newcmd(startline,cmdopts,cmdstr)
	echo "View selection inverted"
endfunction

"-----------------------------------------------------------------------------
" Refresh the allfold view.
" Arguments: none
" Returns: nothing
"
function! AFB_freshen()
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let cmdopts=''
	let startline=line(".")
	call AFB_premark('AFF',cmdopts)
	call AFB_do_command_list(b:cmd_done_list,"list")
	call AFB_finish_newcmd(startline,cmdopts,"")
	echo "View refreshed"
	return
endfunction

"-----------------------------------------------------------------------------
" Remove all fold markers. Undo all allfold operations.
" Arguments: none
" Returns: nothing
"
function! AFB_fold_remove()
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	normal zE
	let startline=line(".")
	set foldmethod&
	if exists( "b:save_foldlevel" )
		exe "set foldlevel=".b:save_foldlevel
	endif
	exe "normal ".startline."Gz."
	let b:af_done=0
	echo "Allfold operations removed"
endfunction

"-----------------------------------------------------------------------------
" Check buffer for existing folds.
" Arguments: none
" Returns: Boolean whether or not folds were found.
"
function! AFB_has_folds()
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let line=1
	let endline=line("$")
	let folds_found=0
	while line<=endline
		if foldlevel(line) | let folds_found=1 | endif
		let line=line+1
	endwhile
	if folds_found
		echoh Error|ec "FOLDS FOUND!"|echoh None
	else
		echoh Error|ec "No folds found."|echoh None
	endif
	return folds_found
endfunction

"-----------------------------------------------------------------------------
" Undo the previous AF command by deleting last command
" from save buffer then do the save cmd buffer as a list.
" Arguments: none
" Returns: nothing
"
function! AFB_undo_prev()
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	if strlen(b:cmd_done_list)==0
		echo "Nothing to undo"
		return
	endif
	let startline=line(".")
	let b:cmd_done_list=AFB_delcmd_fromlist(b:cmd_done_list)
	if strlen(b:cmd_done_list)==0
		call AFB_fold_remove()
		echo "All commands making up view undone"
		return
	endif
	call AFB_init_kxmap(line('$'),g:AFB_map_exclude)
	call AFB_do_command_list(b:cmd_done_list,"list")
	let startline_folded=AFB_fold_markmap(startline,'')
	call AFB_cleanup_for_return(startline,startline_folded)
	echo "Last command making up view undone"
endfunction

"-----------------------------------------------------------------------------
" Save a fold view or a keep/exclude map by appending it to a file
" Arguments: List of command arguments.
"     1. Command options. (Optional)
"		2. Name of register in which to store view or map.
"		3. Map segment length
" Returns: nothing
"
function! AFB_grab_view_map(...)
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let regname='' | let mapseg_length='' | let cmdopts=''
	let ix=0
	while ix < a:0
		let ix=ix+1 | let val=a:{ix}
		if ix==1 && val[0]=='-' | let cmdopts=val | continue | endif
		if regname=='' | let regname=val | continue | endif
		if mapseg_length=='' | let mapseg_length=val | continue | endif
	endwhile
	if regname==''
		echoh Error|ec "No register name specified"|echoh None
		return
	endif
	if ((match(regname,'^[a-zA-Z]')<0)||(strlen(regname)>1))
		echoh Error|ec "Invalid register name specified"|echoh None
		return
	endif
	if mapseg_length=='' | let mapseg_length=64 | endif
	if (match(cmdopts,"-map")>=0) 
		let datatype='map'
	else 
		let datatype='view'
	endif
	if (match(cmdopts,"-use")>=0)
		let startline=line(".")
		call AFB_premark('AFG',cmdopts)
		if datatype=='view'
			let cmdlist=''
			let cmd='let cmdlist=@'.regname[0]
			exe cmd
			call AFB_do_command_list(cmdlist,"list")
		else
			let cmd='let tmpkx=@'.regname[0]
			exe cmd
			let nonmap_chars='[^'.g:AFB_map_keep.g:AFB_map_exclude.']'
			let tmpkx=substitute(tmpkx,nonmap_chars,'','g')
			if strlen(tmpkx)!=line("$")
				echoh Error|ec "Map and file length do not match"|echoh None
				return
			endif
			let b:kx_map=tmpkx
		endif
		call AFB_postmark('AFG',cmdopts)
		if (match(cmdopts,"-list")>=0)
			return
		endif
		let cmdstr='AFG ' 
		if cmdopts!=''
			let cmdstr=cmdstr.cmdopts
		endif
		let cmdstr=cmdstr.' '.regname
		call AFB_finish_newcmd(startline,cmdopts,cmdstr)
		echo datatype "used from register" regname[0]
	else
		let grab_lines=''
		if datatype=='view'
			let grab_lines=b:cmd_done_list
		else
			let start_mapseg=0
			let maplen=strlen(b:kx_map)
			if mapseg_length==0
				let grab_lines=b:kx_map."\n"
			else
				while (start_mapseg<maplen)
					if (maplen-start_mapseg)<mapseg_length 
						let mapseg=strpart(b:kx_map,start_mapseg)
					else
						let mapseg=strpart(b:kx_map,start_mapseg,mapseg_length)
					endif
					let grab_lines=grab_lines.mapseg."\n"
					let start_mapseg=start_mapseg+strlen(mapseg)
				endwhile
			endif
		endif
		let cmd="let @".regname[0]."=grab_lines"
		exe cmd
		echo datatype "grabbed into register" regname[0]
	endif
	return
endfunction

"=============================================================================
"                  Command Processing Utility Functions
"=============================================================================
"
"-----------------------------------------------------------------------------
" Do the processing reguired for a command before marking the kx_map.
" Arguments: cmdopts - Options for command being processed.
" Returns: nothing
"
function! AFB_premark(cmdtype,cmdopts)
	let and_option=match(a:cmdopts,'-and') >= 0
	let or_option=match(a:cmdopts,'-or') >= 0
	let inlist=match(a:cmdopts,'-list')>=0
	let restart_cmdlist=0
	let do_list=1
	if ( ! inlist )
		if ((! and_option)&&(! or_option)) | let restart_cmdlist=1 | endif
		if (a:cmdtype=='AFI')
			if b:cmd_done_list==''
				let restart_cmdlist=1
			else
				let restart_cmdlist=0
			endif
		elseif (a:cmdtype=='AFF')
			let restart_cmdlist=0
		endif
		call AFB_init_kxmap(line('$'),g:AFB_map_exclude)
		if restart_cmdlist
			let b:cmd_done_list=''
		else
			if do_list
				call AFB_do_command_list(b:cmd_done_list,"list")
			endif
		endif
	endif
	"
	"or operations are implicit in the mark map algorithim
   "so there is no need to deal with map_2 and a seperate
	"or function call
	"
	"the AFM command does not mark a map so or must be done
	"
	"another implication is that in views defined manually
	"if successive commands don't have -and/or they are
	"implicitly or'ed together
	"
	"cmd history doesn't have to worry about successive commands
	"without -and/or because a new history list is started
	"everytime a command wo and/or is processed
	"
	if and_option
		let b:kx_map_2=b:kx_map
		let b:kx_map=substitute(b:kx_map,'.',g:AFB_map_exclude,'g')
	elseif or_option && (a:cmdtype=='AFM')
		let b:kx_map_2=b:kx_map
		"no need to clear map since one will be loaded anyway
	endif
endfunction

"-----------------------------------------------------------------------------
" Do the processing reguired for a command after marking the kx_map.
" Arguments: cmdopts - Options for command being processed.
" Returns: nothing
"
function! AFB_postmark(cmdtype,cmdopts)
	"-not is always done first
	if (match(a:cmdopts,"-not")>=0)
		call AFB_not_map()
	endif
	"-and is done if it is present
	if (match(a:cmdopts,"-and")>=0)
		call AFB_and_maps()
	"-or done only if -and not present
	elseif (match(a:cmdopts,"-or")>=0)
			"The marking of a map does an implicit or operation
			"so usually the or operation needn't be done
			"but AFM loads a whole new map instead of marking the old one
			"so the or must done for it.
			if (a:cmdtype=='AFM')
				call AFB_or_maps()
			endif
	endif
endfunction

"-----------------------------------------------------------------------------
" Finish processing reguired for a new command
" Arguments: startline - Current line when command was started.
"            cmdopts   - Command options for command.
"            cmdstr    - Command string of command being finished.
" Returns: nothing
"
function! AFB_finish_newcmd(startline,cmdopts,cmdstr)
	let startline_folded=AFB_fold_markmap(a:startline,a:cmdopts)
	call AFB_cleanup_for_return(a:startline,startline_folded)
	if a:cmdstr!=""
		let b:cmd_done_list=AFB_addcmd_tolist(a:cmdstr,b:cmd_done_list)
	endif
endfunction

"-----------------------------------------------------------------------------
" Add a command to a list of commands.
" Arguments: cmdstr 	- String with command to add to list.
"            cmdlist - String containing command list.
" Returns: nothing
"
function! AFB_addcmd_tolist(cmdstr,cmdlist)
	return a:cmdlist.a:cmdstr.g:AFB_vcmd_sep
endfunction

"-----------------------------------------------------------------------------
" Delete last command from a list of commands.
" Arguments: cmdlist - String containing command list.
" Returns: Command list without last command.
"
function! AFB_delcmd_fromlist(cmdlist)
	if strlen(a:cmdlist)<4
		return ''
	endif
	let start_last_cmd=matchend(a:cmdlist,'^.*'.g:AFB_vcmd_sep.'.')-1
	if start_last_cmd < 0
		let start_last_cmd=0
	endif
	return strpart(a:cmdlist,0,start_last_cmd)
endfunction

"-----------------------------------------------------------------------------
" Do the allfold commands contained in a string which are delimited by '\n'
" Arguments: cmds 	- String containing commands.
"            foldopt - Additional option to add to each command.
" Returns: nothing
"
function! AFB_do_command_list(cmds,foldopt)
	let start_match=0
	while (start_match<strlen(a:cmds))
		let cmd=matchstr(a:cmds,'^.\{-1,}'.g:AFB_vcmd_sep,start_match)
		if cmd=="" | break | endif
		let start_match=start_match+strlen(cmd)
		let cmd=strpart(cmd,0,strlen(cmd)-strlen(g:AFB_vcmd_sep))
		let cmd=AFB_add_cmd_option(a:foldopt,cmd)
		exe cmd
	endwhile
endfunction

"-----------------------------------------------------------------------------
" Add an option to a command.
" Arguments: addopt - Option to add to command string.
"            cmd    - Command string to which option should be added.
" Returns: Command string with option added.
"
function! AFB_add_cmd_option(addopt,cmd)
	let cmd=a:cmd
	let match_opt=matchend(cmd,'^AF[A-Z] \+')
	if match_opt<0 
		 return cmd.' -'.a:addopt
 	endif
	if cmd[match_opt]=='-'
		let cmd=substitute(cmd,'-','-'.a:addopt.'-','')
	else
		let cmd=substitute(cmd,' ',' -'.a:addopt.' ','')
	endif
	return cmd
endfunction

"-----------------------------------------------------------------------------
" Clean up file for return to user.
" Remove manual folds, set fold options, etc.
" Arguments: startline - Current line at start of operation.
"            startline_folded - Indicates startline was folded out of view.
" Returns: nothing
"
function! AFB_cleanup_for_return(startline,startline_folded)
	if (a:startline_folded)
		normal 1G
	else
		exe "normal ".a:startline."G"
	endif
	hi Folded term=standout cterm=bold ctermfg=lightgray ctermbg=15
	normal zM
	let b:af_done=1
endfunction

" Autocommands: {{{

augroup allfold_setup
  au!
  " Run on file type change.
  au FileType * call <SID>AFB_setup()

  " Run on new buffers.
  au BufNewFile,BufRead,BufEnter *
        \   call <SID>AFB_setup()
augroup END

"}}}
"=============================================================================
"                     Buffer/File I/O Functions
"=============================================================================
 
"-----------------------------------------------------------------------------
" Define command set used by allfold package
"
command! -nargs=+ AFB    :call AFB_fold_blocks(<f-args>)
command! -nargs=0 AFF    :call AFB_freshen()
command! -nargs=+ AFG    :call AFB_grab_view_map(<f-args>)
command! -nargs=0 AFH    :call AFB_has_folds()
command! -nargs=? AFI    :call AFB_invert(<f-args>)
command! -nargs=+ AFP    :call AFB_fold_pattern(<f-args>)
command! -nargs=0 AFR    :call AFB_fold_remove()
command! -nargs=0 AFU    :call AFB_undo_prev()

"========== End of script ===========
