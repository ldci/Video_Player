#!/usr/local/bin/red-view
Red [
	Title:   "Red and mpv"
	Author:  "ldci"
	File: 	 %mpv2.red
	Needs:	 View
]

;--for macOS ARM64 and macOS x86
;--you need mpv and socat 
;--Thanks to Red/Sensei for optimisation

helpStr: 
{Some useful shortcuts in the mpv window:
Spacebar or p: pause / resume
Left/right arrows: rewind / fast-forward 5 seconds
Up/down arrows: rewind / fast-forward 1 minute
m: mute
f: full screen
. and ,: frame by frame (useful for viewing a specific movement)
[ and ]: change playback speed
?: display full help in mpv
Q key: Stop current playback and completely close the mpv window.
}

mpvSock: %/tmp/mpvSock ;--we need a socket to communicate with mpv.

w: 720
;h: 480
h: (w * 9) / 16 ;--16/9 ratio
imgSize: as-pair w h
im:  none
img: make image! reduce [imgSize black]
isFile?: false
fileName: none
pause?: false

mpvSend: func [cmd [string!]][
    if exists? mpvSock [
        call/wait/shell rejoin [
            {echo '} cmd {' | socat - UNIX-CONNECT:}
            to-local-file mpvSock
        ]
    ]
]

stopMpv: does [
    mpvSend {{"command":["quit"]}}
]

;--not used, for a future use
setPlaybackPause: func [pause? [logic!]][
    mpvSend rejoin [{{"command": ["set_property", "pause", } either pause? ["true"]["false"] {]}}]
]

playVideo: func [file [file!]][
    if exists? mpvSock [stopMpv] ;--stop previous mpv socket
    call/shell rejoin [
        "mpv --input-ipc-server=" to-local-file mpvSock
        " --force-window=yes "
        {"} to-local-file file {"} " &"       ;; & : does not block Red
    ]
]

loadMovie: does [
	isFile?: false
	sb/text: " "
	fileName: request-file/filter [
    	"Supported Video Files (mpg, mp4, mkv, avi, wmv, mov)"
    	"*.mpg;*.mp4;*.mkv;*.avi;*.wmv;*.mov"
	]
	unless none? fileName [
		sb/text: rejoin [form fileName " : loaded. You can play it!"]
		isFile?: true
	]
]

playMovie: does [
    if isFile? [playVideo to-red-file fileName]
]

; **************************** Main ***************************************
view win: layout [
	title "Read Video with mpv"
	on-close [stopMpv] ;--win event
	button "Load" [loadMovie]
	button "Play" [playMovie]
	button "Quit" [stopMpv quit]
	return
	im: image imgSize img
	area helpStr
	return
	sb: field 720x48 "" wrap
]

