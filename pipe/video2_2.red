Red [
	Title:   "Red and ffmpeg"
	Author:  "ldci"
	File: 	 %video2_2.red
	Needs:	 View
]
;--to be compiled in console mode
OS: system/platform
if any [OS = 'macOS OS = 'Linux ] [home: select list-env "HOME"] 
appDir: to-red-file rejoin [home "/Programmation/Red_ARM/Code/Ffmpeg/pipe/"]
;tmpDir: to-red-file rejoin [appDir "tmp/"] 
;unless exists? tmpDir [make-dir tmpDir]
;ffmpeg-pid-file: %/tmpDir/red-video-ffmpeg.pid
;ffplay-pid-file: %/tmpDir/red-video-ffplay.pid

ffmpeg-pid-file: %/tmp/red-video-ffmpeg.pid
ffplay-pid-file: %/tmp/red-video-ffplay.pid

ffmpeg-pid: none
ffplay-pid: none
paused?: false


w: 720
h: 480
im:  none
img: make image! reduce [as-pair w h black]
prog: copy ""
isFile?: false
delay: 0.02
fileName: none

;--must be before #system
waitPlayback: does [
    while [paused?] [
        do-events/no-wait
        ;wait 0.01
    ]
]

;we need Red/System for pipe commands
#system [
	#include %../lib/ffmpeg.reds
	RSdelay: 0.02 ; RS variable
]

waitfor: func [
	n	[float!]
][
	wait n
]

showImage: func [] [
    if none? ffmpeg-pid [
        ffmpeg-pid: read-pid ffmpeg-pid-file
    ]
    ;print ["PID file:" ffmpeg-pid-file "exists:" exists? ffmpeg-pid-file]
	;if exists? ffmpeg-pid-file [probe read ffmpeg-pid-file]
    im/image: img
    do-events/no-wait
]


getImages: routine [
	command	[string!]
	rimage	[image!]
	delay 	[float!]
	/local 
	cmd		[c-string!]
	pipeIn  [byte-ptr!]
	frame 	[byte-ptr!]
	pixel	[byte-ptr!]
	pixD 	[int-ptr!]
	count	[integer!]
	n		[integer!]
	handle  [ptr-value!]
	w		[integer!]
	h		[integer!]
	r 		[integer!]
	g 		[integer!]
	b		[integer!]
][
	
	RSdelay: delay
	w: IMAGE_WIDTH(rimage/size)
	h: IMAGE_HEIGHT(rimage/size)
	count: (h * w * 3)
	;Allocate a buffer to store frame by frame
	frame: allocate count ;* 2
	cmd: as c-string! string/rs-head command
	;Open input pipe from ffmpeg
	pipeIn: p-open cmd "r" 
	if pipeIn <> null [
		while [count = (h * w * 3)][
			;Read a frame from the input pipe into the buffer
			#call [waitPlayback]
			count: p-read frame 1 h * w * 3 pipeIn
			if count <> (h * w * 3) [break]
			if count = (h * w * 3)[
				handle/value: as int-ptr! 0
				pixD: image/acquire-buffer rimage as ptr-ptr! :handle
				n: 0 
				while [n < count] [
					pixel: frame + n
					r: (as integer! pixel/0)
					g: (as integer! pixel/1) 
					b: (as integer! pixel/2)
					; for a correct rendering in Red 
					pixD/value: (255 << 24) OR (r << 16 ) OR (b << 8) OR g
					pixD: pixD + 1
					n: n + 3	
				]
				image/release-buffer rimage handle/value yes
				#call [waitfor RSdelay]
				#call [showImage]
			]	
		]
		free frame
		p-flush pipeIn
		p-close pipeIn 
	]
]

;--Red/Sensei func
shell-quote: func [s [string!]][
    s: copy s
    replace/all s "'" "'\''"
    rejoin ["'" s "'"]
]


read-pid: func [f [file!]][
    if exists? f [
        attempt [to-integer trim read f]
    ]
]



setPlaybackPause: func [pause? [logic!]][
	;print mold reduce [ffmpeg-pid ffplay-pid paused?]
    pids: copy ""

    if integer? ffmpeg-pid [
        append pids rejoin [" " form ffmpeg-pid]
    ]
    if integer? ffplay-pid [
        append pids rejoin [" " form ffplay-pid]
    ]

    if not empty? pids [
        signal: either pause? ["-STOP"] ["-CONT"]
        call/wait rejoin ["kill " signal pids]
        paused?: pause?
    ]
]

;togglePlayback: does [
;   setPlaybackPause not paused?
;]

generateCommands: does [
    rejoin [
        "echo $$ > " shell-quote to-local-file ffmpeg-pid-file
        ;"; exec ffmpeg -nostdin -i " shell-quote fileName
        "; exec ffmpeg -nostats -loglevel error -i " shell-quote fileName
        " -s 720x480"
        " -f image2pipe"
        " -pix_fmt bgr24"
        " -vcodec rawvideo"
        " -"
    ]
]

startAudio: does [
    if exists? ffplay-pid-file [delete ffplay-pid-file]
    ffplay-pid: none

    call/shell rejoin [
        "sh -c "
        shell-quote rejoin [
            "echo $$ > " shell-quote to-local-file ffplay-pid-file
            "; exec ffplay -nodisp -autoexit -vn "
            shell-quote fileName
        ]
        " >/dev/null 2>&1 &"
    ]
    tries: 0
	while [all [not integer? ffplay-pid tries < 200]] [
    	ffplay-pid: read-pid ffplay-pid-file
    	unless integer? ffplay-pid [
        	do-events/no-wait
        	;wait 0.01
    	]
    	tries: tries + 1
	]
	;print mold reduce [ffplay-pid tries exists? ffplay-pid-file]
	;if exists? ffplay-pid-file [print mold read ffplay-pid-file]
]

loadMovie: does [
	tmp: request-file
	if not none? tmp [
		fileName: form tmp
		sb/text: fileName; form second split-path tmp
		isFile?: true
	]
]

playMovie: does [
    if isFile? [
        ffmpeg-pid: none
        ffplay-pid: none
        paused?: false

        if exists? ffmpeg-pid-file [delete ffmpeg-pid-file]
        if exists? ffplay-pid-file [delete ffplay-pid-file]

        prog: generateCommands
        call/shell prog
        if cb/data [startAudio]
        getImages prog img delay
    ]
]

; **************************** Main ***************************************
view win: layout [
	title "Read Video with pipe"
	button "Load" [loadMovie playMovie]
	;button "Play/Stop" [togglePlayback]
	play-btn: toggle 90x30 "Stop" true [   ;; true = lecture en cours
    	face/text: either face/data ["Stop"]["Play"]
    	setPlaybackPause not face/data     ;; pause? = true quand on met en pause
	]
	
	cb: check "Audio" true
	text "Delay" middle
	sl: slider 100x25 [delay: to-float face/data * 0.10 fD/text: form round/to delay 0.001]
	fD: field 50 "0.02"
	pad 120x0
	button "Quit" [
		call/wait "killall ffplay" 
		quit
	]
	return
	im: image 720x480 img
	return
	sb: field 720 ""
	do [sl/data: 20%]
]

