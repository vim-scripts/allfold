" -------------------------------------
" allfold_full.vim - Version: beta 0.6
" -------------------------------------
" VIM script to display all selected lines with others hidden in closed folds
" Package to add full functionality to allfold_basic.vim
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
 
"=============================================================================
"                           Script Initialization
"=============================================================================
"
if exists("g:AFB_allfold_disabled")
	if g:AFB_allfold_disabled | finish | endif
endif
if exists("g:AFB_allfold_full_disabled")
	if g:AFB_allfold_full_disabled | finish | endif
endif
if ! exists("g:AFB_loaded")
	echoh Error|ec "allfold_basic.vim not loaded, exiting"|echoh None
	finish
endif
if exists("g:AFF_loaded")
	finish
else
	let b:AFF_loaded=1
endif
"
" Initialize script global variables.
"
let s:view_tag = '?'.'[AFV'.']'.'?'
let s:view_section_tag = '?'.'[AFVS'.']'.'?'
let s:map_tag = '?'.'[AFM'.']'.'?'
let s:map_section_tag = '?'.'[AFMS'.']'.'?'
let s:list_tag = '?'.'[AFL'.']'.'?'
let s:list_section_tag = '?'.'[AFLS'.']'.'?'
let s:begin_tag = '?'.'[BGN'.']'.'?'
let s:end_tag = '?'.'[END'.']'.'?'
let s:default_pkg_sl = '#'
let s:arrow_line="--------------------------------------->"

"=============================================================================
"                      Command Implemenation Functions
"=============================================================================
"
"-----------------------------------------------------------------------------
" Request that a file be folded according to a named, predefined view
" consisting of list of allfold commands.
" Arguments: List of command arguments.
"     1. Command options.
"		2. Name of view.
"		3. Name of file in which view is stored.
"     Arguments 3 is optional is assumed to be the current buffer's file.
" Returns: nothing
"
function! s:AFF_fold_view(...)
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let vname=''
	let vfile=''
	let cmdopts=''
	let ix=0
	while ix < a:0
		let ix=ix+1
		let val=a:{ix}
		if ix==1 && val[0]=='-' | let cmdopts=val | continue | endif
		if vname=='' | let vname=val | continue | endif
		if vfile=='' | let vfile=val | continue | endif
	endwhile
	if vname==''
		echoh Error|ec "No view name specified"|echoh None
		return
	endif
	let vfile_arg=vfile
	if exists("b:wks") | let wks=b:wks | else | let wks='' | endif
	let vfile=s:AFF_use_file(vfile,wks,"view","in",bufname('%'))
	if vfile==''
		echoh Error|ec 'Could not determine file for view'|echoh None
		return
	endif
	let startline=line(".")
	let startline_folded=0
	call AFB_premark('AFV',cmdopts)
	let view_cmds=s:AFF_get_data(vfile,"view","file",'',vname)
	if view_cmds==''
		return
	endif
	call AFB_do_command_list(view_cmds,"list")
	call AFB_postmark('AFV',cmdopts)
	if (match(cmdopts,"-list")>=0)
		return
	endif
	let cmdstr='AFV ' 
	if cmdopts!=''
		let cmdstr=cmdstr.cmdopts.' '
	endif
	let cmdstr=cmdstr.vname
	if vfile_arg!=''
		let cmdstr=cmdstr.' '.vfile_arg
	endif
	call AFB_finish_newcmd(startline,cmdopts,cmdstr)
	echo "Got view: ".vname.' from '.vfile
	return
endfunction

"-----------------------------------------------------------------------------
" Command that a file be folded according to a named, predefined map
" of included and excluded lines.
" Arguments: List of command arguments.
"     1. Command options.
"		2. Name of map.
"		3. Name of file in which map is stored.
"     Arguments 3 is optional is assumed to be the current buffer's file.
" Returns: nothing
"
function! s:AFF_fold_map(...)
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let mname='' | let mfile='' | let cmdopts=''
	let ix=0
	while ix < a:0
		let ix=ix+1 | let val=a:{ix}
		if ix==1 && val[0]=='-' | let cmdopts=val | continue | endif
		if mname=='' | let mname=val | continue | endif
		if mfile=='' | let mfile=val | continue | endif
	endwhile
	if mname==''
		echoh Error|ec "No name for map specified"|echoh None
		return
	endif
	let mfile_arg=mfile
	if exists("b:wks") | let wks=b:wks | else | let wks='' | endif
	let mfile=s:AFF_use_file(mfile,wks,"map","in",bufname('%'))
	if mfile==''
		echoh Error|ec 'Could not determine file for view'|echoh None
		return
	endif
	let startline=line(".")
	let startline_folded=0
	call AFB_premark('AFM',cmdopts)
	let newmap=s:AFF_get_data(mfile,"map","file",cmdopts,mname)
	if newmap==''
		return
	endif
	let newmap=substitute(newmap,"\n",'','g')
	let maplen=strlen(newmap)
	let lal=line('$')
	if lal!=maplen
		echoh Error|ec "Map length does not match length of file"|echoh None
		return
	endif
	let b:kx_map=newmap
	call AFB_postmark('AFM',cmdopts)
	if (match(cmdopts,"-list")>=0)
		return
	endif
	let cmdstr='AFM ' 
	if cmdopts!=''
		let cmdstr=cmdstr.cmdopts.' '
	endif
	let cmdstr=cmdstr.mname
	if mfile_arg!=''
		let cmdstr=cmdstr.' '.mfile_arg
	endif
	call AFB_finish_newcmd(startline,cmdopts,cmdstr)
	echo "Got map: "mname.' from '.mfile
	return
endfunction

"-----------------------------------------------------------------------------
" Work with list of fold commands. 
" -out option writes current list to a buffer
" -in  option gets list from a buffer
" Between the out and in options, the list may be edited as desired.
" If neither in or out is specified then -in is assumed.
" If a buffer name is not supplied then the buffer name is obtained from
" either a global variable for the buffer which has previously been used.
" If buffers have not been previously used then a default buffer name is
" constructed.
" Arguments: List of command arguments.
"     1. Command options.
"		2. Name of buffer.  For -out name of buffer in which to save command
"        list.  For -in buffer name from which to read command list.
" Returns: nothing
"
function! s:AFF_fold_list(...)
	let cmdopts=''
	let bufname=''
	let ix=0
	while ix < a:0
		let ix=ix+1
		let val=a:{ix}
		if ix==1 && val[0]=='-' | let cmdopts=val | continue | endif
		if bufname=='' | let bufname=val | continue | endif
	endwhile
	if cmdopts==''
		let cmdopts='-in'
	endif 
	if (match(cmdopts,"-out")>=0)
		"if(match(cmdopts,"-wks")>=0)
		"	let b:wks=bufname
		"endif
		call s:AFF_output_current_cmd_list(cmdopts,bufname)
		return
	endif
	if !exists("b:af_done")
		echoh Error|ec "Can not do AFL command on this buffer"|echoh None
	endif
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	if bufname==''
		let bufname="_.afd"
	endif
	let wks=''
	if exists("b:wks")
		let wks=b:wks
	endif
	let bufname=s:AFF_use_file(bufname,wks,"list","in",bufname("%"))
	if bufname==''
		echoh Error|ec "Could not determine file name to use"|echoh None
		return
	endif
	let startline=line(".")
	let startline_folded=0
	let cmdlist=s:AFF_get_data(bufname,"list","file",cmdopts,'')
	if cmdlist==''
		return
	endif
	call AFB_premark('AFL',cmdopts)
	let b:cmd_done_list=cmdlist
	call AFB_do_command_list(b:cmd_done_list,"list")
	if (match(cmdopts,"-list")>=0)
		return
	endif
	call AFB_finish_newcmd(startline,"","")
	echo "Got command list from: ".bufname
	return
endfunction

"-----------------------------------------------------------------------------
" Output the current command list to a buffer
" Implements -out option of the AF_fold_list
" Arguments: cmdopts - Option string for command
"            bufname - Name of buffer in which to save command list
" Returns: nothing
"
function! s:AFF_output_current_cmd_list(cmdopts,bufname)
	let curbuff=bufname("%")
	let bufname=a:bufname
	if bufname==''
		let bufname="_.afd"
	endif
	let wks=''
	if exists("b:wks")
		let wks=b:wks
	endif
	let bufname=s:AFF_use_file(bufname,wks,"list","out",curbuff)
	if !(exists("b:cmd_done_list"))
		echoh Error|ec "Buffer has no saved command list"|echoh None
		return
	endif
	let cmdlist=b:cmd_done_list
	let erc=s:AFF_save_data(bufname,"list","add",a:cmdopts,cmdlist,'')
	if !erc
		if(match(a:cmdopts,"-wks")>=0)
			let erc=s:AFF_save_data(bufname,"view","add",a:cmdopts,'','')
			if !erc
				let erc=s:AFF_save_data(bufname,"map","add",a:cmdopts,'','')
				let b:wks=bufname
			endif
		endif
	endif
	if erc
		echoh Error|ec "Error saving data #".erc|echoh None
	endif
	let bwnr=bufwinnr(bufname)
	if bwnr<0 | exe "split ".bufname
	else | exe bwnr."wincmd w" | endif
	if(match(a:cmdopts,"-wks")>=0)
		let b:wks_for_buffer=curbuff
	endif
	echo "Saved command list to: ".bufname
endfunction


"-----------------------------------------------------------------------------
" Save a fold view or a keep/exclude map by appending it to a file
" Arguments: List of command arguments.
"     1. Command options. (Optional)
"		2. Name of view or map.
"		3. File name of file in which to store view or map.
"		4. String to start each line when saved.
"		5. String to begin view when saved.
"		6. String to end view when saved.
"     Arguments 3 is optional is assumed to be the current buffer's file.
"     Arguments 4 is optional is assumed to be '#'.
"     Arguments 5 is optional is assumed to be ''.
"     Arguments 6 is optional is assumed to be ''.
" Returns: nothing
"
function! s:AFF_save_view_map(...)
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let vmname='' | let vmfile='' | let sl='' | let bvmw=''
	let evmw=''| let cmdopts=''
	let ix=0
	while ix < a:0
		let ix=ix+1 | let val=a:{ix}
		if ix==1 && val[0]=='-' | let cmdopts=val | continue | endif
		if vmname=='' | let vmname=val | continue | endif
		if vmfile=='' | let vmfile=val | continue | endif
		if sl=='' | let sl=val | continue | endif
		if bvmw=='' | let bvmw=val | continue | endif
		if evmw=='' | let evmw=val | continue | endif
	endwhile
	if vmname==''
		echoh Error|ec "No name for data to save specified"|echoh None
		return
	endif
	let vmfile_arg=vmfile
	if (match(cmdopts,"-map")>=0) | let vm='map' |
	else | let vm='view' | endif
	if exists("b:wks") | let wks=b:wks | else | let wks='' | endif
	let vmfile=s:AFF_use_file(vmfile,wks,vm,'out',bufname('%'))
	if vmfile==''
		echoh Error|ec 'Could not determine file for save'|echoh None
		return
	endif
	let tag=s:{vm}_tag
	if vm=='view'
		let pkg=s:AFF_package_data(tag,vmname,sl,bvmw,evmw,b:cmd_done_list)
	else
		if (match(cmdopts,"-blm")>=0)
			if (wks!='')
				echoh Error|ec 'Begin Line Marker file can not be saved in worksheet'|echoh None
				return
			endif
			if (vmfile_arg=='.')
				echoh Error|ec 'Begin Line Marker file can not be saved in current buffer'|echoh None
				return
			endif
			if (vmfile_arg=='_')
				echoh Error|ec 'Begin Line Marker file can not be saved in global library'|echoh None
				return
			endif
			if (match(vmfile_arg,'\.afd')>=0)
				echoh Error|ec 'Begin Line Marker file can not be saved in .afd file'|echoh None
				return
			endif
			call s:AFF_write_blm_file(cmdopts,vmfile)
			return
		endif
		let mlns='' | let start_mapseg=0 | let seglen=64
		let maplen=strlen(b:kx_map)
		if (match(cmdopts,"-oml")>=0)
			let mlns=b:kx_map
		else
			while (start_mapseg<maplen)
				if (maplen-start_mapseg)<seglen 
					let mapseg=strpart(b:kx_map,start_mapseg)
				else
					let mapseg=strpart(b:kx_map,start_mapseg,seglen)
				endif
				let mlns=mlns.mapseg."\n"
				let start_mapseg=start_mapseg+strlen(mapseg)
			endwhile
		endif
		let pkg=s:AFF_package_data(tag,vmname,sl,bvmw,evmw,mlns)
	endif
	if (match(cmdopts,"-reg")>=0)
		let cmd="let @".vmfile[0]."=pkg"
		exe cmd
		"call AFB_str2reg(cmd_pkg,vmfile)
	else
		let err=s:AFF_save_data(vmfile,vm,"concat",cmdopts,pkg,vmname)
	endif
	echo "Saved map/view ".vmname." to ".vmfile
	return
endfunction

"=============================================================================
"                  Command Processing Utility Functions
"=============================================================================
"
"-----------------------------------------------------------------------------
" Finish processing reguired for a new command
" Arguments: startline - Current line when command was started.
"            cmdopts   - Command options for command.
"            cmdstr    - Command string of command being finished.
" Returns: nothing
"
function! s:AFF_finish_newcmd(startline,cmdopts,cmdstr)
	call AFB_finish_newcmd(a:startline,a:cmdopts,a:cmdstr)
	if exists("b:wks")
		call s:AFF_output_current_cmd_list('',b:wks)
	endif
endfunction

"=============================================================================
"                     Buffer/File I/O Functions
"=============================================================================
"
"-----------------------------------------------------------------------------
" Determine which file is to be used for get/save from current buffer name
" file name argument, possible worksheet, datatype, and whether input or
" output.  Implements use of global library file and directory for allfold
" files.  Also implements file naming by the ".afd" appended to current
" buffer name.
" Arguments: filename  - File name requested by command
"            wksname   - Work sheet name for buffer if any.
"            datatype  - Type of data being gotten/saved.
"            inout     - String 'in' for input, 'out' for output.
"            curbn     - Current buffer name for command.
" Returns: File name and path to use for get/save. Empty string implies
"          that correct file name could not be determined.
"
function! s:AFF_use_file(filename,wksname,datatype,inout,curbn)
	if a:wksname!='' | return a:wksname | endif	
	if a:filename=='_' || a:filename==''
		if exists("g:AFF_libfile")
			return g:AFF_libfile
		else
			return ''
		endif
	endif
	if a:filename=='.'
		return curbn
	endif
	let filename=a:filename
	let lastslash=strridx(filename,'/')
	if lastslash<0
		let lastslash=strridx(filename,'\')
	endif
	if a:filename!='_.afd'
		if (a:filename[0]=='_') && (strlen(a:filename)>1)
			echo "leading underscore"
			if exists("g:AFF_libdir")
				return g:AFF_libdir.strpart(a:filename,1)
			else
				return ''
			endif
		endif
	endif
	if (a:filename!='.afd') && (a:filename!='_.afd')
		return a:filename
	end
	let filename=a:curbn
	let lastslash=-1
	let typeslash=''
	let lastslash=strridx(filename,'/')
	if lastslash>=0
		let typeslash='/'
	else
		let lastslash=strridx(filename,'\')
		if lastslash>=0
			let typeslash='\'
		endif
	endif
	let lastdot=strridx(filename,'.')
	if lastdot<lastslash | let lastdot=-1 | endif
	let fp='' | let fb='' | let fe=''
	if lastslash>=1 
		let fp=strpart(filename,0,lastslash+1)
	endif
	if lastslash>0
		let fbe=strpart(filename,lastslash+1)
	else
		let fbe=filename
	endif
	let lastdotfbe=strridx(fbe,'.')
	if lastdotfbe>0
		let fb=strpart(fbe,0,lastdotfbe)
		let fe=strpart(fbe,lastdotfbe+1)
	else
		let fb=fbe
		let fe=''
	endif
	if a:filename=='.afd'
		if fe==''
			return fp.fb.'.afd'
		else
			return fp.fb.'_'.fe.'.afd'
		endif
	endif
	if a:filename=='_.afd'
		if exists("g:AFF_libdir")
			if fe==''
				return g:AFF_libdir.fb.'.afd'
			else
				return g:AFF_libdir.fb.'_'.fe.'.afd'
			endif
		endif
	endif
	return ''
endfunction

"-----------------------------------------------------------------------------
" Package data with name, start_line, begin_mark, and end_mark.
" Arguments: dtag     - String to use a disinctive tag for lines of data.
"            dname    - Name of data entry to be packaged.
"            startline- String to start each line.
"            beginpkg - String to mark beginning of package.
"            endpkg   - String to mark end of package.
"            lines    - String containing lines making up data to package.
"                       ( Lines seperated by "\n" )
" Returns: String containing packaged data.
"
function! s:AFF_package_data(dtag,dname,startline,beginpkg,endpkg,lines)
	let pkg=''
	let startline=a:startline
	if startline==''
		let startline=s:default_pkg_sl
	endif
	if a:beginpkg != ''
		let pkg=a:beginpkg.startline.a:dtag.':'.a:dname.':'.s:begin_tag."\n"
	endif
	let start_match=0
	while (start_match<strlen(a:lines))
		let line=matchstr(a:lines,'^.\{-1,}'.g:AFB_vcmd_sep,start_match)
		if line=="" | break | endif
		let start_match=start_match+strlen(line)
		let line=strpart(line,0,strlen(line)-1)
		let pkg=pkg.startline.a:dtag.':'.a:dname.':'.line."\n"
	endwhile
	if a:endpkg != ''
		let pkg=pkg.startline.a:dtag.':'.a:dname.':'.s:end_tag.a:endpkg."\n"
	endif
	return pkg
endfunction

"-----------------------------------------------------------------------------
" Save some lines as a section or as all the file. If the lines make up
" a package as indicated by a pkgname, then delete the package first. If a
" secttype is specified then the actions are limited to the section.  If a
" secttype is specified then sectnf determines the action when the section is
" not found. If a section is created for a package delete any other package
" in file before add package to new section.
" Arguments: ofile     - File name of file onto which the data is concat'ed.
"            savesect  - Type of section to use for save.
"            sectnf    - Indication of action to take if section not found.
"            cmdopts   - Command options for command doing save.
"            lines     - String containing lines making up data.
"                         ( Lines seperated by "\n" )
"            pkgname   - Name of data package.
" Returns: Status code of operation. 0 implies success.
"
function! s:AFF_save_data(ofile,savesect,sectnf,cmdopts,lines,pkgname)
	let curwinnr=winnr()
	if ((a:savesect=='concat')||(a:savesect=='file')||(a:savesect==''))
		let section_save=0
	else
		let section_save=1
	endif
	let bwnr=bufwinnr(a:ofile)
	if bwnr<0 | exe "split ".a:ofile
	else | exe bwnr."wincmd w" | endif
	exe "normal 1G0"
	let lal=line('$')
	"exe "redir! >testsave.redir"
	let secttag=''
	let datatag=''
	let bsl=0 | let esl=0
	let section_found=0
	if section_save
		let secttag=s:{a:savesect}_section_tag
		let datatag=s:{a:savesect}_tag
		let bsl=search(escape(secttag.s:begin_tag,"[]"),'w')
		let esl=search(escape(secttag.s:end_tag,"[]"),'w')
		if ((bsl) || (esl))
			if ((!esl) || (!bsl) || (bsl>=esl))
				echoh Error|ec "Invalid section in file"|echoh None
				if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
				return 1
			endif
		endif
		if bsl
			let section_found=1
		endif
	endif
	let gol=1 | let bdl=0 | let edl=0
	let delete_something=1
	let add_section=0
	let pkg_all_file=0
	if section_found
		let bdl=bsl+1 | let edl=esl-1 | let gol=bsl
	else
		if section_save
			if a:sectnf=='add'
				let add_section=1 | let gol='lastline'
				if a:pkgname!='' | let bdl=1 | let edl=lal
				else | let delete_something=0 | endif
			elseif a:sectnf=='iserr'
				echoh Error|ec "Section not found"|echoh None
				if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
			 	return 2
			elseif a:sectnf=='concat'
				let gol='lastline'
				if a:pkgname!='' | let bdl=1 | let edl=lal 
				else | let delete_something=0 | endif
			elseif a:sectnf=='fileadd'
				let bdl=1 | let edl=lal | let gol=1
				let add_section=1
				let delete_something=1
			elseif a:sectnf=='file'
				let bdl=1 | let edl=lal | let gol=1
				let delete_something=1
			else
				echoh Error|ec "Invalid sectnf parameter"|echoh None
				if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
				return 3
			endif
		else
			if ((a:savesect=='file') || (a:savesect==''))
				let bdl=1 | let edl=lal | let gol=1
				let pkg_all_file=1
			elseif a:savesect=='concat'
				let gol='lastline'
				if a:pkgname!='' | let bdl=1 | let edl=lal 
				else | let delete_something=0 | endif
			else
				echoh Error|ec "Internal logic error 1"|echoh None
				if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
				return 4
			endif
		endif
	endif
	let first_data_line=0
	if delete_something && ( bdl<=edl )
		if (a:pkgname=='')||(pkg_all_file)
			exe bdl.','edl."delete"
		else
			let delmatchstr=escape(datatag,"[]").":".a:pkgname.":"
			exe "normal ".bdl."G0"
			if search(delmatchstr, "w") > 0
				if line('.')<=edl
					let gol=line('.')-1
					normal dd
					let edl=edl-1
					while search(delmatchstr, "w") > 0
						if line('.')>edl | break | endif
						normal dd
						let edl=edl-1
					endwhile
				endif
			endif
		endif
	endif
	let lal=line('$')
	if gol=='lastline' | let gol=lal | endif
	if gol<1 | let gol=1 |endif
	exe "normal ".gol."Go"."\e"
	if add_section
		exe "normal i".s:arrow_line.secttag.s:begin_tag."\n\e"
	endif
	if a:lines!=''
		exe "normal i".a:lines."\e"
	endif
	if add_section
		exe "normal i".s:arrow_line.secttag.s:end_tag."\n\e"
	endif
	exe "normal dd"
	if (lal==1) && (getline(lal)=='') | exe "normal 1Gdd" | endif
	if bwnr<0 | exe "wq" | else | exe curwinnr."wincmd w" | endif
endfunction

"-----------------------------------------------------------------------------
" Get some data from a file/buffer.
" Save some lines as a section or as all the buffer. If the lines make up
" a package as indicated by a pkgname, then delete the package first. If a
" secttype is specified then the actions are limited to the section.  If a
" secttype is specified then sectnf determines the action when a section is
" not found. If a section is created for a package delete any other package
" in file before add package to new section.
" Arguments: ifile     - File name of input file.
"            getsect   - Section from which to get data.
"            sectnf    - Indication of action to take if section not found.
"            cmdopts   - Command options for command doing concat.
"            pkgname   - Name of data package to get.
" Returns: Lines of data seperated by "\n"
"
function! s:AFF_get_data(ifile,getsect,sectnf,cmdopts,pkgname)
	let curwinnr=winnr()
	if ((a:getsect=='nosection')||(a:getsect=='file')||(a:getsect==''))
		let section_get=0 | else | let section_get=1 | endif
	let bwnr=bufwinnr(a:ifile)
	if bwnr<0 | exe "split ".a:ifile
	else | exe bwnr."wincmd w" | endif
	exe "normal 1G0"
	let lal=line('$')
	let secttag='' | let datatag='' | let bsl=0 | let esl=0
	let section_found=0
	if section_get
		let secttag=s:{a:getsect}_section_tag
		let datatag=s:{a:getsect}_tag
		let bsl=search(escape(secttag.s:begin_tag,"[]"),'w')
		let esl=search(escape(secttag.s:end_tag,"[]"),'w')
		if ((bsl) || (esl))
			if ((!esl) || (!bsl) || (bsl>=esl))
				echoh Error|ec "Invalid section in file"|echoh None
				if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
				return ''
			endif
		endif
		if bsl | let section_found=1 | endif
	endif
	let bps=1 | let eps=lal
	if section_found | let bps=bsl | let eps=esl
	else
		if section_get
			if a:sectnf=='file'
				"search whole file
			elseif a:sectnf=='' || a:sectnf=='iserr'
				echoh Error|ec "Section for get_data not found"|echoh None
				if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
				return ''
			else
				echoh Error|ec "Invalid sectnf parameter"|echoh None
				if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
				return'' 
			endif
		else
			if a:getsect=='nosection'
				" useless for now and hard to do
				if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
				return ''
			elseif a:getsect=='file' || a:getsect==''
			else
				echoh Error|ec 'Get_data internal error 1'|echoh None
				if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
				return ''
			endif
		endif
	endif
	let blines=0 | let elines=0
	if a:pkgname!=''
		let searchstr=escape(datatag,"[]").":".a:pkgname.":"
		exe "normal ".bps."G0"
		let blines=search(searchstr,'W')
		if blines
			let pl=blines
			while pl<=eps
				if match(getline(pl),searchstr)<0 
					let elines=pl-1 | break | endif
				let pl=pl+1
			endwhile
			if elines==0 | let elines=eps | endif
		endif
	else
		if section_found
			let blines=bps+1 | let elines=eps-1
		else
			let blines=bps | let elines=eps
		endif
	endif
	if ((blines==0) || (elines==0) || (blines>elines))
		echoh Error|ec "Nothing to get for data"|echoh None
		if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
		return ''
	endif 
	let gln=blines
	let lines=''
	let bgnends=escape(s:begin_tag.'\|'.s:end_tag,'[]')
	while gln<=elines
		let gl=getline(gln)
		let gln=gln+1
		if a:pkgname!=''
			let name_endpos=matchend(gl,'^.\+:.\+:')
			if name_endpos>=0
				let gld=strpart(gl,name_endpos)
				if match(gld,bgnends) <0
					let lines=lines.gld."\n"
				endif
			endif
		else
			let lines=lines.gl."\n"
		endif
	endwhile
	if bwnr<0 | exe "q!" | else | exe curwinnr."wincmd w" | endif
	return lines
endfunction

"-----------------------------------------------------------------------------
" Write out the buffer to another file with begin line marker for
" keep(1)/exclude(0) status of the line.
" Arguments: cmdopts	 - Command options.
"            filename - Name of file in which to store blm file.
" Returns: nothing
"
function! s:AFF_write_blm_file(cmdopts,filename)
	exe "%yank"
	let kx_map=b:kx_map
	if ! filewritable(a:filename)
		exe "new" a:filename
	else
		exe "split ".a:filename
		exe "%delete _"
	endif
	exe "put"
	exe "1delete _"
	let startsearch=0
	let startline=0
	exe "%s/^/".g:AFB_map_exclude."/"
	while (1)
	 	let startline=match(kx_map,g:AFB_map_keep,startsearch)
		if startline < 0 | break | endif
	 	let endline=match(kx_map,g:AFB_map_exclude,startline)
		if endline < 0 
			let endline=strlen(kx_map)-1
		else
			let endline=endline-1
		endif
		exe (startline+1).",".(endline+1)."s/^".g:AFB_map_exclude."/".g:AFB_map_keep."/"
		let startsearch=endline+1
		if startsearch>(strlen(kx_map)-1) | break | endif
	endwhile
	exe "wq"
	echo "Begin Line Marker file written"
endfunction

"-----------------------------------------------------------------------------
" Fold a blm file in the current buffer.
" Arguments: none
" Returns: nothing
"
function! s:AFF_fold_blm_file()
	exe "normal 1G0"
	if search('^\_[^'.g:AFB_map_keep.g:AFB_map_exclude.']','w')
		echoh Error|ec "File not properly marked at beginning of lines"|echoh None
		return
	endif
	let startline=line(".")
	let startline_folded=0
	call AFB_premark('AFBL','')
	let lal=line('$')
	let line1=getline(1)
	if line1[0]==g:AFB_map_keep
		call AFB_update_map(0,0,g:AFB_map_keep)
	endif
	exe "normal 1G$"
	while search('^'.g:AFB_map_keep,'W')
		let startkeep=line('.')-1
		if search('^'.g:AFB_map_exclude,'W')
			let endkeep=line('.')-2
		else 
			let endkeep=lal
		endif
		call AFB_update_map(startkeep,endkeep,g:AFB_map_keep)
		if endkeep==lal | break | endif
	endwhile
	call AFB_postmark('BLM','')
	let b:cmds_after_init_map=b:cmds_after_init_map+1
	call AFB_finish_newcmd(startline,'','')
	echo "Begin Line Marker file folded"
	return
endfunction

"-----------------------------------------------------------------------------
" Copy selected or unselected lines to a new buffer.
" Arguments: List of command arguments.
"     1. Command options. (Optional)
"		2. Name of buffer into which lines will be copied.
" Returns: nothing
"
function! s:AFF_copy_to_buffer(...)
	if exists("b:wks_for_buffer")
		exe bufwinnr(b:wks_for_buffer)."wincmd w"
	endif
	let buffname=''
	let cmdopts=''
	let ix=0
	while ix < a:0
		let ix=ix+1
		let val=a:{ix}
		if ix==1 && val[0]=='-' | let cmdopts=val | continue | endif
		if buffname=='' | let buffname=val | continue | endif
	endwhile
	let buffname_arg=buffname
	if (buffname_arg=='.')
		echoh Error|ec 'Lines can not be saved in current buffer'|echoh None
		return
	endif
	if (buffname_arg=='_')
		echoh Error|ec 'Lines can not be saved in global library'|echoh None
		return
	endif
	if (match(buffname_arg,'\.afd')>=0)
		echoh Error|ec 'Lines can not be saved in .afd file'|echoh None
		return
	endif
	let buffname=s:AFF_use_file(buffname,'',"lines","out",bufname('%'))
	if buffname==''
		echoh Error|ec "Could not determine buffer to recieve copy"|echoh None
		return
	endif
	let curbuff=bufname("%")
	let startline=line(".")
	if !bufloaded(buffname)
		exe "edit ".buffname
		let init_winnr=-1
	else
		let init_winnr=bufwinnr(buffname)
		exe "buffer! ".curbuff
	endif
	exe "normal G"
	let last_copy_line=line(".")
	exe "buffer! ".curbuff
	let startmatching=0
	if (match(cmdopts,"-uns")>=0)
		let stopcopyval=g:AFB_map_keep
		let copyval=g:AFB_map_exclude
	else
		let copyval=g:AFB_map_keep
		let stopcopyval=g:AFB_map_exclude
	endif
	let cutcnt=0
	while (1)
	 	let found_copy=match(b:kx_map,copyval,startmatching)
		if found_copy <0 | break | endif
	 	let found_stop=match(b:kx_map,stopcopyval,found_copy)
		if found_stop < 0 
			let found_stop=strlen(b:kx_map)-1
		else
			let found_stop=found_stop-1
		endif
		if (match(cmdopts,"-cut")>=0)
			exe (found_copy+1-cutcnt).",".(found_stop+1-cutcnt)"delete" 
			let cutcnt=cutcnt+(found_stop-found_copy)+1
		else
			exe (found_copy+1).",".(found_stop+1)"yank" 
		endif
		exe "buffer! ".buffname
		exe "normal G0p"
		exe "buffer! ".curbuff
		let startmatching=found_stop+1
		if startmatching>(strlen(b:kx_map)-1) | break | endif
	endwhile
	exe "buffer! ".buffname
	exe "normal 1Gdd"
	exe "buffer! ".curbuff
	exe "normal ".startline."G"
	if (match(cmdopts,"-cut")>=0)
		call AFB_freshen()
	endif
	if init_winnr<0
		exe "split ".buffname
	else
		exe init_winnr."wincmd w"
		exe init_winnr."wincmd w"
	endif
	exe "normal ".last_copy_line."G"
	echo "Copied lines to: ".buffname
endfunction

"-----------------------------------------------------------------------------
" Define command set used by allfold package
"
command! -nargs=+ AFC    :call s:AFF_copy_to_buffer(<f-args>)
command! -nargs=? AFL    :call s:AFF_fold_list(<f-args>)
command! -nargs=+ AFM    :call s:AFF_fold_map(<f-args>)
command! -nargs=0 AFQ    :call s:AFF_fold_blm_file()
command! -nargs=+ AFS    :call s:AFF_save_view_map(<f-args>)
command! -nargs=+ AFV    :call s:AFF_fold_view(<f-args>)

"========== End of script ===========
