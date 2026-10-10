#!/usr/local/bin/red-view
Red [
	Title:   "macOS FFMPEG Player"
	Author:  "ldci"
	File: 	 %ffplay.red
	Needs:	 View
]

;--test with ffplay
fileName: ""
prog: "" 
isFile?: false

command: {List of commands while running
q, ESC: Quit.
f: Toggle full screen.
p, SPC: Pause.
m: Toggle mute.
9, 0:  Decrease and increase volume respectively.
/, *: Decrease and increase volume respectively.
a: Cycle audio channel in the current program.
v: Cycle video channel.
t: Cycle subtitle channel in the current program.
c: Cycle program.
w: Cycle video filters or show modes.
s: Step to the next frame.
left/right: Seek backward/forward 10 seconds.
down/up: Seek backward/forward 1 minute.
page down/page up :Seek to the previous/next chapter. or if there are no chapters Seek backward/forward 10 minutes.
right mouse click: Seek to percentage in file corresponding to fraction of width.
left mouse double-click: Toggle full screen.
}

;--Red/Sensei func
shell-quote: func [s [string!]][
    s: copy s
    replace/all s "'" "'\''"
    rejoin ["'" s "'"]
]


loadFile: does [
	isFile?: false
	tmp: request-file
	if not none? tmp [
		fileName: to string! to-file tmp
		win/text: fileName
		isFile?: true
	]
]

playFile: does [
	if isFile? [
		call/shell rejoin ["ffplay -autoexit "  shell-quote fileName] 
	]
]

view win: layout/flags/options [
	title "macOS ffplay"
	origin 10x10 space 10x10
	button "Load" [loadFile]
	button "Play" [playFile]
	pad 290x0
	button "Quit" [call "killall ffplay" Quit]
	return
	info: area 500x280
	do [info/text: command]
][resize] [offset: 0x0]
