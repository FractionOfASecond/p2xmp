
# use 'sudo make install' to install p2xmp in /usr/local/bin

DEST=/usr/local/bin

install: ${DEST}/p2xmp

/usr/local/bin/p2xmp: p2xmp
	install p2xmp ${DEST}
