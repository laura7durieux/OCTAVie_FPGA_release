//#define OS_POSIX
//#define OS_WIN

#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include <fcntl.h>

#ifdef OS_POSIX
#include <sys/ioctl.h>
#include <asm/termbits.h>
#endif

#include <glib/gprintf.h>
#include <gtk/gtk.h>
#include <gtk/gtkpicture.h>
#include "io.h"

#ifdef OS_WIN
#include <windows.h>
    #define RX_SIZE         4096    /* taille tampon d'entrée  */
    #define TX_SIZE         4096    /* taille tampon de sortie */
    #define MAX_WAIT_READ   100     /* temps max d'attente pour lecture (en ms) */

    /* Délais d'attente sur le port COM */
    COMMTIMEOUTS g_cto =
    {
        MAX_WAIT_READ,  /* ReadIntervalTimeOut          */
        0,              /* ReadTotalTimeOutMultiplier   */
        MAX_WAIT_READ,  /* ReadTotalTimeOutConstant     */
        0,              /* WriteTotalTimeOutMultiplier  */
        0               /* WriteTotalTimeOutConstant    */
    };
    
    /* Configuration du port COM */
    DCB g_dcb =
    {
        sizeof(DCB),        /* DCBlength            */
        3000000,            /* BaudRate             */
        TRUE,               /* fBinary              */
        FALSE,              /* fParity              */
        FALSE,              /* fOutxCtsFlow         */
        FALSE,              /* fOutxDsrFlow         */
        DTR_CONTROL_ENABLE, /* fDtrControl          */
        FALSE,              /* fDsrSensitivity      */
        FALSE,              /* fTXContinueOnXoff    */
        FALSE,              /* fOutX                */
        FALSE,              /* fInX                 */
        FALSE,              /* fErrorChar           */
        FALSE,              /* fNull                */
        RTS_CONTROL_ENABLE, /* fRtsControl          */
        FALSE,              /* fAbortOnError        */
        0,                  /* fDummy2              */
        0,                  /* wReserved            */
        0x100,              /* XonLim               */
        0x100,              /* XoffLim              */
        8,                  /* ByteSize             */
        NOPARITY,           /* Parity               */
        ONESTOPBIT,         /* StopBits             */
        0x11,               /* XonChar              */
        0x13,               /* XoffChar             */
        '?',                /* ErrorChar            */
        0x1A,               /* EofChar              */
        0x10                /* EvtChar              */
    };

#endif



// COM port reading thread
void* read_com(void* data)
{
    // common data
    AppState* state = (AppState*)data;

    // thread variables
    gint buffer_to_write;   // buffer number
    guint buffer_pos;       // buffer offset
    char* buffer;           // buffer pointer
    unsigned char c;
#ifdef OS_POSIX
    int com_fd;             // COM port ID
#endif
#ifdef OS_WIN
    HANDLE com_fd;          // COM port HANDLE
#endif
    // serial communication
    guint32 errorCount;
#ifdef OS_POSIX   
    struct termios2 tty_param;
#endif   
    // initialization
    state->read_com_read_state = STATE_USART_IDLE;
    state->read_com_please_stop_reading = FALSE;
    state->read_com_please_quit = FALSE;
    state->read_com_call = FALSE;
    // multi-threading condition
    if(pthread_cond_init(&state->read_com_cond, NULL))
    {   
        perror(ERR_READ_COM);
        exit(EXIT_FAILURE);
    }
    // COM port
    errorCount = 0;
    buffer_pos = 0;
#ifdef OS_POSIX
    com_fd = COM_OPEN_ERROR;
#endif

#ifdef OS_WIN
    com_fd = (HANDLE)COM_OPEN_ERROR;
#endif

    // main infinite loop
    while(1) 
    {
        // wait for condition
        // mutex lock
        if(pthread_mutex_lock(&state->read_com_mutex))
        {
            perror(ERR_READ_COM);
            exit(EXIT_FAILURE);
        }
        // wait for start signal
        while(!state->read_com_call) {
            if(pthread_cond_wait(&state->read_com_cond, &state->read_com_mutex))
            {
                perror(ERR_READ_COM);
                exit(EXIT_FAILURE);
            }
        }
        state->read_com_call = FALSE;
       
        // Set writing buffer number
        buffer_to_write = (state->buffer_filled)?0:1;
        
        // check if it should quit
        if(state->read_com_please_quit)
        {
            state->read_com_please_quit = FALSE;
            if(pthread_mutex_unlock(&state->read_com_mutex))
            {
                perror(ERR_READ_COM);
                exit(EXIT_FAILURE);
            }
            break;
        }
        
        // Open COM port
#ifdef OS_POSIX
        com_fd = open(state->com_path, O_RDONLY);
#endif
#ifdef OS_WIN
        com_fd = CreateFile(state->com_path, GENERIC_READ|GENERIC_WRITE, 0, NULL,
                        OPEN_EXISTING, FILE_ATTRIBUTE_SYSTEM, NULL);
#endif
        
#ifdef OS_POSIX
        if (com_fd == COM_OPEN_ERROR) {
#endif
#ifdef OS_WIN
        if (com_fd == INVALID_HANDLE_VALUE) {
#endif
            fprintf(stderr,ERR_READ_COM_STRING,state->com_path);
            perror(ERR_READ_COM); 
            state->read_com_read_state = STATE_USART_IDLE;
        } else {
            // Change state
            state->read_com_read_state = STATE_USART_READING;
            
            // COM port configuration
#ifdef OS_POSIX
            // POSIX COM port configuration
            // reset tty_param structure
            memset(&tty_param, 0, sizeof(tty_param));
            // get current configuration
            if(ioctl(com_fd, TCGETS2, &tty_param))
            {
                perror(ERR_READ_COM);
                state->read_com_read_state = STATE_USART_IDLE;
                close(com_fd);
            }
            // adjust flags
            tty_param.c_iflag = 0;        // raw input mode
            //tty_param.c_iflag &= ~IGNBRK; // Ignore break

            tty_param.c_lflag = 0;        // Non canonic mode
            
            tty_param.c_cc[VMIN]  = 32;   // 32 byte min
            tty_param.c_cc[VTIME] = 1;    // Timeout 0.1 seconds
            
            tty_param.c_cflag = (tty_param.c_cflag & ~CSIZE) | CS8; // 8 bits
            tty_param.c_cflag |= (CLOCAL|CREAD);                    // Reading mode
            tty_param.c_cflag &= ~(PARENB | PARODD);                // No parity
            tty_param.c_cflag |= CSTOPB;                            // 2 stop bit
            tty_param.c_cflag &= ~CRTSCTS;                          // No hardware flow control
            // set baud rate
            tty_param.c_cflag &= ~CBAUD;
            tty_param.c_cflag |= BOTHER;  // Non standard baud rate
            tty_param.c_ispeed = 3000000; // 3Mbit/s
            tty_param.c_ospeed = 3000000; // 3Mbit/s
            
            // set new parameters
            if(ioctl(com_fd, TCSETS2, &tty_param))
            {
                perror(ERR_READ_COM);
                state->read_com_read_state = STATE_USART_IDLE;
                close(com_fd);
            }
#endif
#ifdef OS_WIN
            // Windows COM port configuration
            // TODO

            /* affectation taille des tampons d'émission et de réception */
            SetupComm(com_fd, RX_SIZE, TX_SIZE);
        
            /* configuration du port COM */
            if(!SetCommTimeouts(com_fd, &g_cto) || !SetCommState(com_fd, &g_dcb))
            {
                perror(ERR_READ_COM);
                state->read_com_read_state = STATE_USART_IDLE;
                CloseHandle(com_fd);
            }
#endif
            
        }
        // mutex_unlock
        if(pthread_mutex_unlock(&state->read_com_mutex))
        {
            perror(ERR_READ_COM);
            exit(EXIT_FAILURE);
        }
        
        // if COM port open, go to reading loop
        // go back to wait state otherwise
        if(state->read_com_read_state == STATE_USART_READING)
        {
            buffer = state->data_buffer[buffer_to_write];
            // COM port synchronize
            c=0;
            while((c&0xC0)!=0xC0) {
                // search for first start byte
                while((c&0xC0)!=0xC0)
                {
#ifdef OS_POSIX
                    if(read(com_fd, &c, 1) != 1)
#endif
#ifdef OS_WIN
                    if(!ReadFile(com_fd, &c, 1, NULL, NULL)) // TODO read one byte in c and check return code different than 1 one read
#endif
                    {
                        g_printf("Oups ! Data loss step 1...\n");
                        break;
                    }
                }
                buffer[0]=c;
                // first one found, search for the second
#ifdef OS_POSIX
                if(read(com_fd, &c, 1) != 1)
#endif
#ifdef OS_WIN
                if(!ReadFile(com_fd, &c, 1, NULL, NULL)) // TODO read one byte in c and check return code different than 1 one read
#endif          
                {
                    g_printf("Oups ! Data loss step 2...\n");
                    break;
                }
                buffer[1]=c;
                // second one found, search for the third
#ifdef OS_POSIX
                if(read(com_fd, &c, 1) != 1)
#endif
#ifdef OS_WIN
                if(!ReadFile(com_fd, &c, 1, NULL, NULL)) // TODO read one byte in c and check return code different than 1 one read
#endif          
                {
                    g_printf("Oups ! Data loss step 2...\n");
                    break;
                }
                buffer[2]=c;
            }
            
            buffer += 3;
            buffer_pos = 3;

            // end of first data pack
#ifdef OS_POSIX
            if(read(com_fd, buffer, DATA_BUFFER_PACK-3) != DATA_BUFFER_PACK-3)
#endif
#ifdef OS_WIN
            if(!ReadFile(com_fd, buffer, DATA_BUFFER_PACK-3, NULL, NULL)) // TODO read DATA_BUFFER_PACK-3 bytes in buffer and check
#endif
                g_printf("Oups ! Data loss step 3...\n");
            buffer += DATA_BUFFER_PACK-3;
            buffer_pos += DATA_BUFFER_PACK-3;
            
            while(buffer_pos < DATA_BUFFER_SIZE)
            {                    
                // data pack
#ifdef OS_POSIX
                if(read(com_fd, buffer, DATA_BUFFER_PACK) != DATA_BUFFER_PACK)
#endif
#ifdef OS_WIN
                if(!ReadFile(com_fd, buffer, DATA_BUFFER_PACK, NULL, NULL))
#endif
                    g_printf("Oups ! Data loss step 4...\n");
                buffer += DATA_BUFFER_PACK;
                buffer_pos += DATA_BUFFER_PACK;
            }
            buffer_pos = 0;
            g_printf("Synchronized\n");
            
            // COM port reading loop
            while(1)
            {
                buffer = state->data_buffer[buffer_to_write];
                while(1) {
                    while(buffer_pos < DATA_BUFFER_SIZE)
                    {                    
                        // data pack
#ifdef OS_POSIX
                        if(read(com_fd, buffer, DATA_BUFFER_PACK) != DATA_BUFFER_PACK)
#endif
#ifdef OS_WIN
                        if(!ReadFile(com_fd, buffer, DATA_BUFFER_PACK, NULL, NULL))
#endif
                            g_printf("Oups ! Data loss step 5...\n");
                        buffer += DATA_BUFFER_PACK;
                        buffer_pos += DATA_BUFFER_PACK;
                    }
                    buffer_pos = 0;
                    
                    // check is synchronization not lost
                    buffer = state->data_buffer[buffer_to_write];
                    //if((buffer[0]&0xC0)&&(buffer[1]&0xC0)) // Check 2 bytes
                    if((buffer[0]&0xC0)&&(buffer[1]&0xC0)&&(buffer[2]&0xC0)) // Check 3 bytes
                        break;
                    
                    // send a blank frame to replace the current corrupted frame
                    memset(buffer, 0, DATA_BUFFER_SIZE);
                    // swap buffer
                    if(pthread_mutex_lock(&state->read_com_mutex))
                    {
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }
                    state->buffer_filled=buffer_to_write;
                    buffer_to_write = (buffer_to_write)?0:1;
                    if(pthread_mutex_unlock(&state->read_com_mutex))
                    {
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }
                    // send first blank line
                    // activate record data thread
                    if(pthread_mutex_lock(&state->record_data_mutex))
                    {
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }
#ifdef DEBUG
printf("Call record thread\n");
#endif
                    state->record_data_call = TRUE;
                    if(pthread_cond_signal(&state->record_data_cond))
                    {   
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }
                    if(pthread_mutex_unlock(&state->record_data_mutex))
                    {
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }
                    // activate update_graph thread
                    if(pthread_mutex_lock(&state->update_graph_mutex))
                    {
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }
#ifdef DEBUG
printf("Call plot thread\n");
#endif
                    state->update_graph_call = TRUE;
                    if(pthread_cond_signal(&state->update_graph_cond))
                    {   
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }
                    if(pthread_mutex_unlock(&state->update_graph_mutex))
                    {
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }
                    
                    // COM port resynchronize
                    buffer = state->data_buffer[buffer_to_write];
                    c=0;
                    while((c&0xC0)!=0xC0) {
                        while((c&0xC0)!=0xC0)
                        {
#ifdef OS_POSIX
                            if(read(com_fd, &c, 1) != 1)
#endif
#ifdef OS_WIN
                            if(!ReadFile(com_fd, &c, 1, NULL, NULL))
#endif                      
                            {
                                g_printf("Oups ! Data loss step r1...\n");
                                break;
                            }
                        }
                        buffer[0]=c;
#ifdef OS_POSIX
                        if(read(com_fd, &c, 1) != 1)
#endif
#ifdef OS_WIN
                        if(!ReadFile(com_fd, &c, 1, NULL, NULL))
#endif                      
                        {
                            g_printf("Oups ! Data loss step r2...\n");
                            break;
                        }
                        buffer[1]=c;
#ifdef OS_POSIX
                        if(read(com_fd, &c, 1) != 1)
#endif
#ifdef OS_WIN
                        if(!ReadFile(com_fd, &c, 1, NULL, NULL))
#endif                      
                        {
                            g_printf("Oups ! Data loss step r2...\n");
                            break;
                        }
                        buffer[2]=c;
                    }

                    buffer += 3;
                    buffer_pos = 3;

                    // end of first data pack
#ifdef OS_POSIX
                    if(read(com_fd, buffer, DATA_BUFFER_PACK-3) != DATA_BUFFER_PACK-3)
#endif
#ifdef OS_WIN
                    if(!ReadFile(com_fd, buffer, DATA_BUFFER_PACK-3, NULL, NULL)) // TODO read DATA_BUFFER_PACK-3 bytes in buffer and check
#endif
                        g_printf("Oups ! Data loss step r3...\n");
                    buffer += DATA_BUFFER_PACK-3;
                    buffer_pos += DATA_BUFFER_PACK-3;

                    while(buffer_pos < DATA_BUFFER_SIZE)
                    {                    
                        // data pack
#ifdef OS_POSIX
                        if(read(com_fd, buffer, DATA_BUFFER_PACK) != DATA_BUFFER_PACK)      
#endif
#ifdef OS_WIN
                        if(!ReadFile(com_fd, buffer, DATA_BUFFER_PACK, NULL, NULL)) // TODO read DATA_BUFFER_PACK bytes in buffer and check
#endif
                            g_printf("Oups ! Data loss step r4...\n");
                        buffer += DATA_BUFFER_PACK;
                        buffer_pos += DATA_BUFFER_PACK;
                    }
                    buffer_pos = 0;
                    g_printf("Transmission error n°%d\r", ++errorCount);fflush(stdout);
                    // swap buffer again and break to finally sent a second blank frame to replace the one lost during the resynchronization process
                    if(pthread_mutex_lock(&state->read_com_mutex))
                    {
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }
                    state->buffer_filled=buffer_to_write;
                    buffer_to_write = (buffer_to_write)?0:1;
                    if(pthread_mutex_unlock(&state->read_com_mutex))
                    {
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }                
                    break;
                }
                
                // swap buffer
                if(pthread_mutex_lock(&state->read_com_mutex))
                {
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }
                state->buffer_filled=buffer_to_write;
                buffer_to_write = (buffer_to_write)?0:1;
                if(pthread_mutex_unlock(&state->read_com_mutex))
                {
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }
                // activate record data thread
                if(pthread_mutex_lock(&state->record_data_mutex))
                {
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }
#ifdef DEBUG
printf("Call record thread\n");
#endif
                state->record_data_call = TRUE;
                if(pthread_cond_signal(&state->record_data_cond))
                {   
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }
                if(pthread_mutex_unlock(&state->record_data_mutex))
                {
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }
                // activate update_graph thread
                if(pthread_mutex_lock(&state->update_graph_mutex))
                {
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }
#ifdef DEBUG
printf("Call plot thread\n");
#endif
                state->update_graph_call = TRUE;
                if(pthread_cond_signal(&state->update_graph_cond))
                {   
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }
                if(pthread_mutex_unlock(&state->update_graph_mutex))
                {
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }
                // check if it should stop or quit
                /*if(pthread_mutex_lock(&state->read_com_mutex))
                {
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }*/
                if(state->read_com_please_quit)
                {
                    state->read_com_please_stop_reading = TRUE;
                }
                if(state->read_com_please_stop_reading)
                {
                    // how much transmission erros ?
                    g_printf("Total transmission errors : %d\nStop reading\n", errorCount);
                    // close the COM port
#ifdef OS_POSIX
                    close(com_fd);
#endif
#ifdef OS_WIN
                    CloseHandle(com_fd);
#endif
                    state->read_com_please_stop_reading = FALSE;
                    state->read_com_read_state = STATE_USART_IDLE;
                    if(state->read_com_please_quit)
                    {
                        state->read_com_please_quit = FALSE;
                        /*if(pthread_mutex_unlock(&state->read_com_mutex))
                        {
                            perror(ERR_READ_COM);
                            exit(EXIT_FAILURE);
                        }*/
                        return(NULL);
                    }
                    /*if(pthread_mutex_unlock(&state->read_com_mutex))
                    {
                        perror(ERR_READ_COM);
                        exit(EXIT_FAILURE);
                    }*/
                    break;
                }
                /*if(pthread_mutex_unlock(&state->read_com_mutex))
                {
                    perror(ERR_READ_COM);
                    exit(EXIT_FAILURE);
                }*/
            }
        }  
    }
    // End
    return(NULL);
}

// File transfert function
void* record_data(void* data) {
    // common data
    AppState* state = (AppState*)data;
    
    // local variables
    int i,j,v,c;
    char* buffer;           // pointer to input binary data
    char time_line[4096];   // buffer for one line of the output file

    // initialization
    state->record_data_state = STATE_RECORD_IDLE;
    state->record_data_please_quit = FALSE;
    state->record_data_call = FALSE;
    // multi-threading condition
    if(pthread_cond_init(&state->record_data_cond, NULL))
    {   
        perror(ERR_RECORD_DATA);
        exit(EXIT_FAILURE);
    }    
    
    // main infinite loop
    while(1)
    {
        // wait for condition
        if(pthread_mutex_lock(&state->record_data_mutex))
        {
            perror(ERR_RECORD_DATA);
            exit(EXIT_FAILURE);
        }
        while(!state->record_data_call) {
            if(pthread_cond_wait(&state->record_data_cond, &state->record_data_mutex))
            {
                perror(ERR_RECORD_DATA);
                exit(EXIT_FAILURE);
            }
        }
        state->record_data_call = FALSE;
        
        if(state->record_data_please_quit)
        {
            state->record_data_please_quit = FALSE;
            if(pthread_mutex_unlock(&state->record_data_mutex))
            {
                perror(ERR_RECORD_DATA);
                exit(EXIT_FAILURE);
            }
            break;
        }
        if(pthread_mutex_unlock(&state->record_data_mutex))
        {
            perror(ERR_RECORD_DATA);
            exit(EXIT_FAILURE);
        }
        
#ifdef DEBUG
printf("Record now\n");
#endif

        // get pointer to buffer to record
        buffer = state->data_buffer[state->buffer_filled];
                
        /*// Save the previously filled buffer if record_data_state vaut STATE_RECORD_RECORD
        if(state->record_data_state == STATE_RECORD_RECORD) {
            fprintf(state->output_file, "%12.5f",TIME_RESOLUTION*(float)(state->timestamp));
            state->timestamp++;
            j=0;
            v=(buffer[j++]&0x3F)<<6;
            v|=(buffer[j++]&0x3F);
            fprintf(state->output_file, "%d",v);
            for(i=1; i < DATA_BUFFER_WORDS; i++) 
            {
                v=(buffer[j++]&0x3F)<<6;
                v|=(buffer[j++]&0x3F);
                fprintf(state->output_file, ";%d",v);
            }
            fprintf(state->output_file, "\n");
        }*/
    
        // Save the previously filled buffer if record_data_state vaut STATE_RECORD_RECORD
        if(state->record_data_state == STATE_RECORD_RECORD) {
            // build one line of the output csv file
            c = sprintf(time_line, "%12.5f;",TIME_RESOLUTION*((float)(state->timestamp++)));
            j=0;
            v  = (buffer[j++]&0x3F)<<6;
            v |= (buffer[j++]&0x3F);
            c += sprintf(time_line+c, "%5d",v);
            for(i=1; i < DATA_BUFFER_WORDS; i++) 
            {
                v  = (buffer[j++]&0x3F)<<6;
                v |= (buffer[j++]&0x3F);
                c += sprintf(time_line+c, ";%5d",v);
            }
            // write one line in the csv file
            fprintf(state->output_file, "%s\n", time_line);
        }
    }
    
    // End
    return(NULL);
}

// File transfert function
void* update_graph(void* data) {
    // common data
    AppState* state = (AppState*)data;
     // local variables
    guint8 r,g,b;
    gint i,j,k,v;
    gint column;
    char* buffer;
    GdkTexture* new_texture;
    
    // initialization
    state->update_graph_please_quit = FALSE;
    state->update_graph_call = FALSE;
    column = WIDTH-1;

    // multi-threading condition
    if(pthread_cond_init(&state->update_graph_cond, NULL))
    {   
        perror(ERR_UPDATE_GRAPH);
        exit(EXIT_FAILURE);
    }    
    
    // main infinite loop
    while(1)
    {
        // wait for condition
        if(pthread_mutex_lock(&state->update_graph_mutex))
        {
            perror(ERR_UPDATE_GRAPH);
            exit(EXIT_FAILURE);
        }
        while(!state->update_graph_call) {
            if(pthread_cond_wait(&state->update_graph_cond, &state->update_graph_mutex))
            {
                perror(ERR_UPDATE_GRAPH);
                exit(EXIT_FAILURE);
            }
        }
        state->update_graph_call = FALSE;
        
#ifdef DEBUG
printf("Plot now\n");
#endif        
        // check if it should quit
        if(state->update_graph_please_quit)
        {
            state->update_graph_please_quit = FALSE;
            if(pthread_mutex_unlock(&state->update_graph_mutex))
            {
                perror(ERR_UPDATE_GRAPH);
                exit(EXIT_FAILURE);
            }
            break;
        }
        if(pthread_mutex_unlock(&state->update_graph_mutex))
        {
            perror(ERR_UPDATE_GRAPH);
            exit(EXIT_FAILURE);
        }
        // increment column
        column++;
        column%=WIDTH;

        /*if(pthread_mutex_lock(&state->read_com_mutex))
        {
            perror(ERR_READ_COM);
            exit(EXIT_FAILURE);
        }*/
        buffer = state->data_buffer[state->buffer_filled];
        /*if(pthread_mutex_unlock(&state->read_com_mutex))
        {
            perror(ERR_RECORD_DATA);
            exit(EXIT_FAILURE);
        }*/
        // update gtkpicture
        k=STRIDE*(HEIGHT-1)+(column<<2);
        j=0;
        for(i=0 ; i<HEIGHT ; i++)
        {
            v=(buffer[j++]&0x3F)<<6;
            v|=(buffer[j++]&0x3F);
            value_to_color(v, &r, &g, &b);
            state->raw_image[k]=r;
            state->raw_image[k+1]=g;
            state->raw_image[k+2]=b;
            k-=STRIDE;
        }
        if(!(column&0x3F))  // update display each 64 frames
        {
            new_texture = gdk_texture_new_for_pixbuf(state->pixbuf);
            gtk_picture_set_paintable(state->picture, GDK_PAINTABLE(new_texture));
            g_object_unref(new_texture);
        }
    }
    // End
    return(NULL);
}
