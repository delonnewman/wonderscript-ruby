.PHONY: all clean

CC=bin/wsc

all: dist/runtime.js dist/runtime.min.js

dist/runtime.js:
	$(CC) src/runtime.js.ws | uglifyjs --beautify > dist/runtime.js

dist/runtime.min.js:
	$(CC) src/runtime.js.ws | uglifyjs > dist/runtime.min.js

clean:
	rm dist/runtime.js
	rm dist/runtime.min.js
