#include <glib/gprintf.h>
#include <gtk/gtk.h>
#include <gtk/gtkpicture.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
//#include <pthread.h>

#include "gui.h"

// Function to map a value to a color
void value_to_color(int value, guint8 *r, guint8 *g, guint8 *b) {
    // variables 
    float scale;
    //
    scale = (float)value / MAX_RAW_DATA_VALUE;  // linear scale [0:1]
    scale = log10(1+9*scale);                   // log scale [0:1]
    if(scale < (1.0/3.0)) {
        scale *= 3;
        *r = 0;
        *g = (guint8)(scale * 255.0);
        *b = (guint8)(47.0 + scale * 208.0); 
    } else if (scale < (2.0/3.0)){
        scale -= (1.0-3.0); scale *= 3;
        *r = (guint8)(scale * 255.0);
        scale = 1.0 - scale;
        *g = (guint8)(scale * 255);
        *b = (guint8)(255);
    } else {
        scale -= (2.0-3.0); scale = 1.0 - 3.0*scale;
        *r = (guint8)(scale * 255.0);
        *g = (guint8)(255);
        *b = (guint8)(255);
    }
}


// function to create an empty picture
void create_empty_picture(gpointer data)
{
    // variables
    //GByteArray *pixels;
    GBytes *bytes;
    GdkTexture *texture;
    guchar *pixels;
    guint8 r,g,b,a;
    gint i,j,k;
    
    // common data
    AppState* state = (AppState*)data;
    
    // memory allocation for raw_image
    state->raw_image = malloc(STRIDE*HEIGHT);
    if(state->raw_image == NULL)
    {
        perror(ERR_UPDATE_GRAPH);
        exit(EXIT_FAILURE);
    }
    state->pixbuf = gdk_pixbuf_new_from_data(state->raw_image, GDK_COLORSPACE_RGB, TRUE, 8, WIDTH, HEIGHT, STRIDE, NULL, NULL); 
    //pixels = gdk_pixbuf_get_pixels(state->pixbuf);
    //
    value_to_color(0, &r, &g, &b);
    a=255;
    for (j = 0; j < HEIGHT; j++) {
        k=j*STRIDE;
        for (i = 0; i < WIDTH; i++) {
            state->raw_image[k++]=r;
            state->raw_image[k++]=g;
            state->raw_image[k++]=b;
            state->raw_image[k++]=a;
        }
    }
    texture = gdk_texture_new_for_pixbuf(state->pixbuf);
    gtk_picture_set_paintable(state->picture, GDK_PAINTABLE(texture));
    g_object_unref(texture);    
    // quit
    return;
}

// Function to draw the X axis in the bottom drawing area
/*static*/ void draw_X_axis(GtkDrawingArea *drawing_area, cairo_t *cr, int width, int height, gpointer data) {
    
    // Set the line width
    cairo_set_line_width(cr, AXIS_WIDTH);

    // Draw the axis line
    cairo_move_to(cr, 0, 10);
    cairo_line_to(cr, width, 10);
    cairo_stroke(cr);

    // Draw the tick marks and labels
    for (int i = 0; i <= 10; i++) {
        double x = i * width / 10.0;
        cairo_move_to(cr, x, 0);
        cairo_line_to(cr, x, 20);
        cairo_stroke(cr);

        // Draw the labels
        char label[10];
        snprintf(label, sizeof(label), "%.1f", i * (TIME_RESOLUTION*WIDTH)/10.0);
        cairo_move_to(cr, x, 30);
        cairo_show_text(cr, label);
    }

    // Draw the axis label
    cairo_move_to(cr, width / 2 - 30, 40);
    cairo_show_text(cr, "time [s]");
}

// Function to draw the Y axis in the left drawing area
/*static*/ void draw_Y_axis(GtkDrawingArea *drawing_area, cairo_t *cr, int width, int height, gpointer data) {
    cairo_text_extents_t extents;
    double x,y;

    // Set the line width
    cairo_set_line_width(cr, AXIS_WIDTH);

    // Draw the axis line
    cairo_move_to(cr, width-10, 0);
    cairo_line_to(cr, width-10, height);
    cairo_stroke(cr);

    // Draw the tick marks and labels
    for (int i = 0; i <= 5; i++) {
        double x = i * height / 5.0;
        cairo_move_to(cr, width, x);
        cairo_line_to(cr, width-20, x);
        cairo_stroke(cr);

        // Draw the labels
        char label[10];
        snprintf(label, sizeof(label), "%2dk", (5-i)*(int)round((FREQ_RESOLUTION*HEIGHT)/(5000.0)));
        cairo_move_to(cr, width-40, x);
        cairo_show_text(cr, label);
    }

    // Draw the axis label
    cairo_text_extents (cr, "frequency [Hz]", &extents);
    x = (width-60)-(extents.height/2 + extents.y_bearing);
    y = (height / 2)+(extents.width/2 + extents.x_bearing);
    cairo_move_to(cr, x, y);
    cairo_rotate(cr, -1.5708); // angle en radian pour faire - 90°
    cairo_show_text(cr, "frequency [Hz]");
}

// Callback to init GUI and handle application startup
// Main GTK function
void app_activated_cb(GtkApplication *app, gpointer user_data) {
    // variables
    AppState *state;
    
    GtkWindow *window;
    GtkWidget *grid;
    
    GtkWidget *drawing_area_bottom;
    GtkWidget *drawing_area_left;
    
    GtkWidget *button_start;
    GtkWidget *button_record;
    GtkWidget *button_stop;
    
    GtkWidget *label_com_port;
    GtkEntryBuffer *entry_buffer_com_port;
    GtkWidget *entry_com_port;
    
    GtkWidget *label_com_port_path;
    GtkEntryBuffer *entry_buffer_com_port_path;
    GtkWidget *entry_com_port_path;
    
    GtkWidget *label_output_filename;
    GtkEntryBuffer *entry_buffer_output_filename;
    GtkWidget *entry_output_filename;

    // tmp char buffer for string manipulation
    char buffer[1024];
    
    // Application state
    state = (AppState *)user_data;
    
    // Main window
    window = GTK_WINDOW(gtk_application_window_new(app));
    
    // Grid
    grid = gtk_grid_new();
    gtk_window_set_child(window, grid);

    // FFT graph on the right side
    // Two columns on the right side (middle and right) to draw the bitmap and its X and Y axis
    //********************************
    // bitmap on right side
    state->picture = GTK_PICTURE(gtk_picture_new());
    gtk_grid_attach(GTK_GRID(grid), GTK_WIDGET(state->picture), 3, 0, 1, 5);
    create_empty_picture(state);
    // X axis (time)
    drawing_area_bottom = gtk_drawing_area_new();
    gtk_drawing_area_set_draw_func(GTK_DRAWING_AREA(drawing_area_bottom), draw_X_axis, NULL, NULL);
    gtk_widget_set_size_request(drawing_area_bottom, WIDTH, 48);
    gtk_grid_attach(GTK_GRID(grid), drawing_area_bottom, 3, 5, 1, 1);
    // Y axis (frequency)
    drawing_area_left = gtk_drawing_area_new();
    gtk_drawing_area_set_draw_func(GTK_DRAWING_AREA(drawing_area_left), draw_Y_axis, NULL, NULL);
    gtk_widget_set_size_request(drawing_area_left, 100, HEIGHT);
    gtk_grid_attach(GTK_GRID(grid), drawing_area_left, 2, 0, 1, 5);
    
    // Buttons
    // Two columns on the left side of the main window
    //********************************
    // Start button
    button_start = gtk_button_new_with_label("Start");
    gtk_grid_attach(GTK_GRID(grid), button_start, 0, 0, 2, 1);
    g_signal_connect (button_start, "clicked", G_CALLBACK (cb_button_start), (gpointer) state);
    // Record button
    button_record = gtk_button_new_with_label("Record");
    gtk_grid_attach(GTK_GRID(grid), button_record, 0, 1, 2, 1);
    g_signal_connect (button_record, "clicked", G_CALLBACK (cb_button_record), (gpointer) state);
    // Stop button
    button_stop = gtk_button_new_with_label("Stop");
    gtk_grid_attach(GTK_GRID(grid), button_stop, 0, 2, 2, 1);
    g_signal_connect (button_stop, "clicked", G_CALLBACK (cb_button_stop), (gpointer) state);

    // User defined fields
    // Two columns on the left side of the main window
    //********************************
    // Com port selection
    label_com_port = gtk_label_new("Com port :");
    gtk_grid_attach(GTK_GRID(grid), label_com_port, 0, 3, 1, 1);   
    sprintf(buffer,"%d",DEFAULT_COM_PORT);
    entry_buffer_com_port = gtk_entry_buffer_new(buffer,8);
    state->com_port = DEFAULT_COM_PORT;
    entry_com_port = gtk_entry_new_with_buffer(entry_buffer_com_port);
    state->com_port_entry = entry_com_port;
    gtk_grid_attach(GTK_GRID(grid), entry_com_port, 1, 3, 1, 1);
    
    // Com port path selection
    label_com_port_path = gtk_label_new("Com path :");
    gtk_grid_attach(GTK_GRID(grid), label_com_port_path, 0, 4, 1, 1);   
    entry_buffer_com_port_path = gtk_entry_buffer_new(DEFAULT_LINUX_COM_PORT_PATH,48);
    strcpy(state->com_path,DEFAULT_LINUX_COM_PORT_PATH);
    entry_com_port_path = gtk_entry_new_with_buffer(entry_buffer_com_port_path);
    state->com_path_entry = entry_com_port_path;
    gtk_grid_attach(GTK_GRID(grid), entry_com_port_path, 1, 4, 1, 1);
    
    // Output directory selection
    label_output_filename = gtk_label_new("Output file :");
    gtk_grid_attach(GTK_GRID(grid), label_output_filename, 0, 5, 1, 1);    
    entry_buffer_output_filename = gtk_entry_buffer_new(DEFAULT_OUTPUT_FILE,48);
    strcpy(state->output_filename,DEFAULT_OUTPUT_FILE);
    entry_output_filename = gtk_entry_new_with_buffer(entry_buffer_output_filename);
    state->output_filename_entry = entry_output_filename;
    state->output_file = NULL;
    gtk_grid_attach(GTK_GRID(grid), entry_output_filename, 1, 5, 1, 1);
    
    // Display the main window
    gtk_window_present(window);

    return;
}

// Start button callback function
void cb_button_start(GtkWidget *widget, gpointer *data)
{
    // variables
    AppState *state;
    gchar buffer[1024];
        
    // get state pointer
    state = (AppState *)data;
    

    // activate com port reading
    if(pthread_mutex_lock(&state->read_com_mutex))
    {
        perror(ERR_CB_BUTTON_START);
        exit(EXIT_FAILURE);
    }
    if(state->read_com_read_state == STATE_USART_IDLE )
    {
        // read the com port in GUI + update AppState
        state->com_port = atoi(gtk_editable_get_text(GTK_EDITABLE(state->com_port_entry)));
        snprintf(buffer, 1024, "%s%d", gtk_editable_get_text(GTK_EDITABLE(state->com_path_entry)), state->com_port);
        strcpy(state->com_path, buffer);
        state->read_com_call = TRUE;
        if(pthread_cond_signal(&state->read_com_cond))
        {
            perror(ERR_CB_BUTTON_START);
            exit(EXIT_FAILURE);
        }
    }
    if(pthread_mutex_unlock(&state->read_com_mutex))
    {
        perror(ERR_CB_BUTTON_START);
        exit(EXIT_FAILURE);
    }
    
    // quit
    return;
}

// Record button callback function
void cb_button_record(GtkWidget *widget, gpointer *data)
{
    // variables
    AppState *state;
    
    // get state pointer
    state = (AppState *)data;
    

    if(pthread_mutex_lock(&state->record_data_mutex))
    {
        perror(ERR_CB_BUTTON_RECORD);
        exit(EXIT_FAILURE);
    }
    // NEW : 
    g_printf(MSG_LAUNCH_REC);

    //
    if(!state->output_file)
    {
        state->timestamp = 0;
        // read the output filename + upadate AppState
        strcpy(state->output_filename,gtk_editable_get_text(GTK_EDITABLE(state->output_filename_entry)));
        state->output_file = fopen(state->output_filename,"wb");
        if(state->output_file == NULL)
        {
            g_printf(MSG_ERR_CREATE_FILE, state->output_filename);
            state->record_data_state == STATE_RECORD_IDLE;
        } else {
            g_printf(MSG_CREATE_FILE, state->output_filename);
            state->record_data_state = STATE_RECORD_RECORD;
        }
    }
    //
    if(pthread_mutex_unlock(&state->record_data_mutex))
    {
        perror(ERR_CB_BUTTON_RECORD);
        exit(EXIT_FAILURE);
    }
    
    // quit
    return;
}

// Stop button callback function
void cb_button_stop(GtkWidget *widget, gpointer *data)
{
    // variables
    AppState *state;

    // get state pointer
    state = (AppState *)data;
    
    // stop com port reading
    if(pthread_mutex_lock(&state->read_com_mutex))
    {
        perror(ERR_CB_BUTTON_STOP);
        exit(EXIT_FAILURE);
    }
    //
    if(state->read_com_read_state == STATE_USART_READING )
    {
        state->read_com_please_stop_reading = TRUE;
    }
    //
    if(pthread_mutex_unlock(&state->read_com_mutex))
    {
        perror(ERR_CB_BUTTON_STOP);
        exit(EXIT_FAILURE);
    }
    
    // close output file if opened
    if(pthread_mutex_lock(&state->record_data_mutex))
    {
        perror(ERR_CB_BUTTON_STOP);
        exit(EXIT_FAILURE);
    }
    //
    if(state->output_file != NULL) {
        fclose(state->output_file);
        state->output_file = NULL;
        state->record_data_state = STATE_RECORD_IDLE;
    }
    //
    if(pthread_mutex_unlock(&state->record_data_mutex))
    {
        perror(ERR_CB_BUTTON_STOP);
        exit(EXIT_FAILURE);
    }
        
    // quit
    return;
}
