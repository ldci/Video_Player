Red [
	Title:   "Red and ffmpeg"
	Author:  "ldci"
	File: 	 %video1.red
	Needs:	 View
]

;--à compiler en mode console

;we need Red/System for pipe 
#system [
	#include %../lib/ffmpeg.reds
]

OS: system/platform
if any [OS = 'macOS OS = 'Linux ] [home: select list-env "HOME"] 
if any [OS = 'MSDOS OS = 'Windows][home: select list-env "USERPROFILE"]
appDir: to-red-file rejoin [home "/Programmation/Red_ARM/Code/Ffmpeg/pipe/"] 

srcName: rejoin [form appDir "Homer.mp4"]
dstName: rejoin [form appDir "Homer2.mp4"]
tmpName: rejoin [form appDir "tmp.mp4"] 
imageSize: 646x480 
buffer: make vector! [char! 8 930240] ; w * h * 3 

processImages: routine [
	buf			[vector!]
	commandr	[string!]
	commandw	[string!]
	return: 	[integer!]
	/local 
	cmdr		[c-string!]
	cmdw		[c-string!]
	pipeIn  	[byte-ptr!]
	pipeOut  	[byte-ptr!]
	frame 		[byte-ptr!]	
	count		[integer!]
	tvalue		[integer!]
	n			[integer!]
][
	;a vector array to store frame by frame
	frame: vector/rs-head buf
	count:  vector/rs-length? buf
	tValue: count
	cmdr: as c-string! string/rs-head commandr
	cmdw: as c-string! string/rs-head commandw
	;Open input and output pipes from ffmpeg
	pipeIn:  p-open cmdr "r" 
	pipeOut: p-open cmdw "w" 
	while [count = tValue] [
		;Read a frame from the input pipe into the buffer
		count: p-read frame 1 tValue pipeIn
		;if count <> tValue [break]
		;Process the current frame
		n: 0 
		while [n < count] [
			;print [n count]
			;Invert each colour component in every pixel
			frame/n: as byte! (255 - frame/n)
			n: n + 1
		]
		;write frame to the output pipe
		p-write frame 1 tValue pipeOut
	]
	p-flush pipeIn p-flush pipeOut
	p-close pipeIn p-close pipeOut
	0
]


ffmpegr: rejoin [
	"ffmpeg"				;location of ffmepg binary
	" -i '" srcName	"'"		;source name
	" -f image2pipe"		;image file muxer writes video frames to pipe 
	" -pix_fmt rgb24"		;rgb values
	" -vcodec rawvideo"		;raw data
	" -"					;for pipe
]

ffmpegw: rejoin [
	"ffmpeg" 				;location of ffmepg binary
	" -y" 					;replace file if exists
	" -f rawvideo"			;raw data
	" -vcodec rawvideo" 	;raw data
	" -pix_fmt rgb24" 		;rgb values
	" -s " imageSize 		;output size
	" -r 29"				;FPS (3000/1001)
	" -i -"					;we use a pipe 
	" -f mp4"				;mp4 format
	" -q:v 1"				;best image quality
	" -an" 					;no sound
	" -vcodec mpeg4" 		;video codec
	" '" tmpName "'"		;output name
]


;********************** Main ***********************************
ret: processImages buffer ffmpegr ffmpegw
print ["Processing video... Done: " form ret]
;-- On garde plutôt l’audio du fichier source lors de la création finale :
;--pas besoin créer un MP3 intermédiaire
call/wait rejoin [
    "ffmpeg -y -i '" tmpName "' -i '" srcName
    "' -map 0:v:0 -map 1:a:0? -c:v copy"
    " -c:a aac -b:a 128k -shortest"
    " '" dstName "'"
]

if exists? to-file tmpName [delete to-file tmpName]
print "Playing movie "
ret: call/wait rejoin ["ffplay "  dstName]

comment [
	;--from Red/Sensei
	_ffmpegw: rejoin [
    "ffmpeg -y"
    " -f rawvideo -pixel_format rgb24"
    " -video_size " imageSize
    " -framerate 29 -i -"
    " -an -c:v libx264 -preset medium -crf 23"
    " -pix_fmt yuv420p -movflags +faststart"
    " '" tmpName "'"
	]
	changer l'échelle de la vidéo
	-vf "scale=640:480:force_original_aspect_ratio=decrease,pad=640:480:(ow-iw)/2:(oh-ih)/2"
]





