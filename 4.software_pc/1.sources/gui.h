#ifndef GUI_H
#define GUI_H

#include "io.h"
#include "msg.h"
#include <pthread.h>

//***************************************************
// DEFINE
//***************************************************

//#define BYTES_PER_R8G8B8 3
#define WIDTH 1000
#define STRIDE 4096 /* >=4 × WIDTH */
#define HEIGHT 256
//#define MAX_COLOR_VALUE 255
#define AXIS_WIDTH 2

#define MAX_RAW_DATA_VALUE 4096
//#define TIME_RESOLUTION 0.00256                     /* in sec  */
#define TIME_RESOLUTION 0.00512                       /* in sec  */
#define FREQ_RESOLUTION (2/TIME_RESOLUTION)           /* in kHz */
//#define DATA_CHUNK (int)(0.1 / TIME_RESOLUTION)     /* 50 points (assuming 1000 samples/2.56  second)*/

#define STATE_USART_IDLE 0
#define STATE_USART_READING 1

#define STATE_RECORD_IDLE 0
#define STATE_RECORD_RECORD 1

#define DATA_BUFFER_PACK 32
#define DATA_BUFFER_WORDS 256
#define DATA_BUFFER_SIZE (DATA_BUFFER_WORDS<<1)

//***************************************************
// Data
//***************************************************

// Data structure to store the application's state
typedef struct {
    GtkWidget* com_port_entry;          // associated GUI entry
    GtkWidget* output_filename_entry;   // associated GUI entry
    GtkWidget* com_path_entry;          // associated GUI entry
        
    pthread_t read_com_th;              // COM port reading thread
    pthread_cond_t read_com_cond;       // Condition to call read_com thread
    pthread_mutex_t read_com_mutex;     // Mutex
    gint read_com_call;                 // Spurious wake-up mngt
    gint read_com_read_state;           // reading state
    gint read_com_please_stop_reading;  // ask to stop reading
    gint read_com_please_quit;          // ask to end the COM port thread
    char* data_buffer[2];               // data buffers
    gint buffer_filled;                 // buffer filled that can be recorded

    pthread_t record_data_th;           // File transfert thread
    pthread_cond_t record_data_cond;    // Condition to call record_data thread
    pthread_mutex_t record_data_mutex;  // Mutex
    gint record_data_call;              // Spurious wake-up mngt
    gint record_data_state;             // record state
    gint record_data_please_quit;       // ask to stop the record thread
    gchar output_filename[1024];        // output filename
    gchar com_path[1024];               // Linux com port path
    gint com_port;                      // current com_port
    FILE* output_file;                  // FILE pointer to output file
    
    pthread_t update_graph_th;          // Update graph thread
    pthread_cond_t update_graph_cond;   // Condition to call update_graph thread
    pthread_mutex_t update_graph_mutex; // Mutex
    gint update_graph_call;             // Spurious wake-up mngt
    gint update_graph_please_quit;      // ask to end the update graph thread
    gint rows;                          // FFT height
    gint cols;                          // FFT width
    GtkPicture* picture;                // picture to display FFT
    GdkPixbuf* pixbuf;                  // pixbuf
    guchar* raw_image;                  // raw_image
    
    unsigned long int timestamp;        // timing (n° of frame since beginning of recording)
    
} AppState;


//***************************************************
// Prototypes
//***************************************************
// Refresh window
gboolean update_display(gpointer user_data);

// Function to map a value to a color
void value_to_color(int value, guint8 *r, guint8 *g, guint8 *b);

// function to create an empty picture
void create_empty_picture(gpointer data);

// Function to draw the X axis in the bottom drawing area
void draw_X_axis(GtkDrawingArea *drawing_area, cairo_t *cr, int width, int height, gpointer data);

// Function to draw the Y axis in the left drawing area
void draw_Y_axis(GtkDrawingArea *drawing_area, cairo_t *cr, int width, int height, gpointer data);

//***************************************************
// Callbacks
//***************************************************

// Callback to init GUI and handle application startup
void app_activated_cb(GtkApplication *app, gpointer user_data);

// Start button callback function
void cb_button_start(GtkWidget *widget, gpointer *data);

// Record button callback function
void cb_button_record(GtkWidget *widget, gpointer *data);

// Stop button callback function
void cb_button_stop(GtkWidget *widget, gpointer *data);

#endif
