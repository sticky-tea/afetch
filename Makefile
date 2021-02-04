all:
	fasm afetch.asm
	chmod +x afetch
install:
	install afetch /usr/local/bin
