SKETCH = main

HOME = C:/Users/andre

FQBN = teensy:avr:teensy40

TEENSY_PORT = usb:0/140000/0/1
PORT = COM3

LIBS = $(HOME)/Documents/Arduino/libraries

build: $(SKETCH).ino
	arduino-cli compile --libraries $(LIBS) --fqbn $(FQBN) $(SKETCH).ino

flash:
	arduino-cli upload -p $(TEENSY_PORT) --fqbn $(FQBN) .
	make listen	

clean:
	rm -rf obj

edit:
	vim $(SKETCH).ino

listen:
	python -m serial.tools.miniterm --exit-char 3 $(PORT) 115200
