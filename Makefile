MAC-P8 = /Applications/PICO-8.app/Contents/MacOS/pico8


run:
	${MAC-P8} -run volleyball.p8

web:
	${MAC-P8} -x volleyball.p8 -export public/index.html