
               ======= ======= ==== === ======= === =======
               Getting Started With The allfold VIM Scripts
               ======= ======= ==== === ======= === =======

                             February 28, 2003

Introduction:
=============

The allfold scripts implement a feature set which allows VIM users to view
interesting lines in a buffer and FOLD the rest away.  Lines are selected to
be interesting in one of the two following ways: 

1. They match a regular expression pattern.
2. They are in a block of lines delimited inclusively by a line that matches
   a beginning RE pattern and a line that matches an ending RE pattern.

Sets of lines matching different selection criteria can be combined using
logical "and" and "or" operations. The selections may be inverted so that
lines not matching the selection criteria are actually selected.

Beyond these basics other features do such things as manipulating lists of
selection commands and using the raw selection "bit-map" directly to enhance
the capabilities and ease of use of the scripts.

Some people may be familiar with the "ALL" command in the IBM mainframe
XEDIT editor which does the very basic function of displaying only those lines
containing a given string.  These scripts introduce the same concept to VIM in
a greatly enhanced form that include, among other things, regular expressions,
blocks of lines, and logical combinations of selections.

Developer Comments:
========= =========

Once I had the basic functions working I found many, many ways to add to their
capabilities as I used, tested, and documented the scripts.  Eventually I
split most of these more advanced and special purpose features off into a
separate script that can be manually loaded separately when full command
implementation is needed.  The basic functionality is incorporated in one much
smaller script which does the work 80% of the time, and which I prefer to load
for each file being edited from a command in the .vimrc file.

One word of warning is required for VIM users that have manual folds defined
in a file.  THESE SCRIPTS DELETE ALL MANUAL FOLDS BEFORE DOING ANYTHING!!!

This software must be considered to be beta level currently because I have
been the sole user, tester, and developer.  The basic script, named
allfold_basic.vim, should be much more stable than the full implementation
script, named allfold_full.vim. I would say the basic script should be 80-90 %
of the way to a gamma version while the full implementation is probably more
like 60-70%.

It has been a lot of fun developing a tool that has already proven to be of
great use for me.  The VIM scripting language in version 6+ has proven quite
powerful once, I got over the worst of a steep learning curve. Working around
my regular job requirements and at home, it took about six weeks to develop
this package.

I have been quite impressed with the speed of the scripts which do a good bit
of programmatic processing including loops.  On a fairly good Linux server I
find most operations to be done almost instantly when working with a thousand
line source code file.  I did some testing and development on a modest laptop
running Windows 2000 and did not encounter any unusual performance problems
either.  I optimized operations for the case where a few scattered lines or
blocks were selected as opposed to the case where most of the lines are
selected and only a few folded away.

I have tried to write a fairly complete document describing the allfold
scripts and their functionality, but I'm sure my bias as the developer has
blinded me from some obvious points of confusion which need to be addressed.
This documentation file is included as allfold_doc.txt.

Good Luck and Happy All-Folding!
Marion W. Berryman
mwberryman-at-copper-dot-net

Linux/UNIX Installation:
========== =============

1. Unzip the gzip tar file in a convenient location.
   For example create a directory named vim/allfold
	under your current home directory.  Move the
   allfold.gz file to this directory and issue the
   following command:

   tar -xvzf allfold.gz

2. Add lines to your .vimrc file to source in the scripts
   if you would like for them to always be loaded when
   you edit a file.

	Example:

   source /home/myself/vim/allfold/allfold_basic.vim
   source /home/myself/vim/allfold/allfold_full.vim
   
	The allfold_full.vim is optional, and, in fact, it is not
   recommended that this script be loaded by default
   for every file.  The basic file can be loaded automatically
   and whenever necessary the full version can be added
	by manually typing the source command. 

	Of course you could avoid automatically loading either
	script automatically since even the basic script is 
	fairly large.  If you issue the source commands manually,
   be sure to always source the basic script first.
   
3. If you are going to be using the full version, two
   VIM global variables can be set in the .vimrc file to
   help manage storing and retrieving allfold data. These
   variables are AFF_libfile and AFF_libdir and are 
   discussed in the documentation file allfold_doc.txt.
   
	Example:

	let AFF_libfile='/home/myself/vim/allfold/aflib.afd'
	let AFF_libdir='/home/myself/vim/allfold/libdr/'

	There is an example of an allfold library file in
   the distribution package with sections for views
   and maps already defined.  This skeleton is named
	"example_aflib.afd".

4. Finally you can add the following commands to 
   the .vimrc file to disable the allfold scripts:

	Disable any allfold loading:
	let AFB_allfold_disabled=1       

	Disable only the full version:
	let AFB_allfold_full_disabled=1

5. Read the file allfold_doc.txt which is part
   of this distribution for a full description
   of the commands supported by the allfold package.



Windows Installation:
======= =============

Basically follow the same steps as for Linux/UNIX.
Winzip can unzip the compressed tar file in Step 1.
Instead of editing .vimrc edit your _vimrc file
in the top level of the VIM program directory.
Be sure to use Windows names for files and directories
ie Put a drive letter first and use backslashes.

End of readme.txt.
