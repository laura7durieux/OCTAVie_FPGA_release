OCTAVie : main.o gui.o io.o 
	gcc main.o gui.o io.o -o OCTAVie `pkg-config gtk4 --libs` -lm -lpthread
	
main.o : main.c gui.h io.h msg.h
	gcc -c `pkg-config gtk4 --cflags` main.c -D_REENTRANT -DOS_WIN

gui.o : gui.c gui.h io.h msg.h
	gcc -c `pkg-config gtk4 --cflags` gui.c -D_REENTRANT -DOS_WIN

io.o : io.c gui.h io.h msg.h
	gcc -c `pkg-config gtk4 --cflags` io.c -D_REENTRANT -DOS_WIN
	
clean:
	rm *.o
