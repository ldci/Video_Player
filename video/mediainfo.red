#!/usr/local/bin/red-view
Red [
	Title:   "FFMPEG Player"
	Author:  "ldci"
	File: 	 %mediainfo.red
	Needs:	 View
]

;--Thanks to Red/SenSei for optimisation
 
darkMode: yes
either darkMode [fcolor: white] [fcolor: black]

fileName: ""
fn: ""
isFile?: false
mode: "default"

margins: 5x5

generateCommands: does [
	blk: rejoin [
		"ffprobe"	
		" -show_format"
		" -show_streams"
		" -print_format " mode
		" -i '" fileName "'"							
	]
]

readOutPut: does [
	outPut: copy {}
    call/wait/output generateCommands outPut        
    info/text: outPut
]

loadFile: does [
	isFile?: false
	tmp: request-file
	if not none? tmp [
		fileName: to string! to-file tmp
		fn: to-string second split-path tmp
		either cb/data [sb/text: copy fileName] [sb/text: copy fn]
		isFile?: true
		readOutPut
	]
]

view win: layout[
	title "Media Infos [ffprobe]"
	origin margins space margins
	origin 10x10 space 10x10
	button 50 "Load" 			[loadFile]
	cb: check "Show directory" 	[either face/data [sb/text: copy fileName] [sb/text: copy fn]]
	text 40 "Mode" middle
	dp: drop-down 70 data ["default" "flat" "ini" "json" "xml"]
		select 1
		on-change [
			mode: pick face/data face/selected
			if isFile? [readOutPut]
		]
	
	button 30 "+"  			[fs/data: fs/data + 1]
	fs: field 30 "12" 		react [info/font/size: fs/data]
	button 30 "-"  			[fs/data: max 1 fs/data - 1]
	button 50 "Quit" 		[call "killall ffprobe" Quit]
	return
	info: area 500x300 font [name: "Arial" size: 12 color: fcolor] 
	return
	sb: base 500x20 font [name: "Arial" size: 12 color: fcolor] 
]
