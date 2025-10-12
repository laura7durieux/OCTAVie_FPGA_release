#include <gtk/gtk.h>
#include <gtk/gtkpicture.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "gui.h"
#include "io.h"
#include "msg.h"

int main(int argc, char* argv[])
{
    int status;
    
    // common data
    AppState state;
    
    // Init state
    state.output_file == NULL;
    
    // data buffers
    state.buffer_filled = 1;
    if((state.data_buffer[0]=malloc(DATA_BUFFER_SIZE))==NULL)
    {
        perror(ERR_MAIN);
        exit(1);
    }
    if((state.data_buffer[1]=malloc(DATA_BUFFER_SIZE))==NULL)
    {
        perror(ERR_MAIN);
        exit(1);
    }
    
    // multi-threading mutex
    if(pthread_mutex_init(&state.read_com_mutex, NULL))
    {   
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }    
    if(pthread_mutex_init(&state.record_data_mutex, NULL))
    {   
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    if(pthread_mutex_init(&state.update_graph_mutex, NULL))
    {   
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }

    // COM port reading thread
    if(pthread_create(&state.read_com_th, NULL, read_com, &state))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    // File transfering thread
    if(pthread_create(&state.record_data_th, NULL, record_data, &state))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    // Update graph thread
    if(pthread_create(&state.update_graph_th, NULL, update_graph, &state))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    
    // Create a new GTK application
    GtkApplication *app = gtk_application_new("com.OCTAVie", G_APPLICATION_DEFAULT_FLAGS);
    if (!G_IS_OBJECT(app)) {
            perror(ERR_MAIN);
            g_printerr("Error: Failed to initialize GtkApplication\n");
            return EXIT_FAILURE;
        }

    g_signal_connect(app, "activate", G_CALLBACK(app_activated_cb), &state);

    // Run the GTK application
    status = g_application_run(G_APPLICATION(app), argc, argv);
    // Unref the application object
    g_object_unref(app);
    
    // stop all threads
    // mutex lock
    if(pthread_mutex_lock(&state.read_com_mutex))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    state.read_com_please_quit = TRUE;
    state.read_com_call = TRUE;
    if(pthread_cond_signal(&state.read_com_cond))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    if(pthread_mutex_unlock(&state.read_com_mutex))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    //
    if(pthread_mutex_lock(&state.record_data_mutex))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    state.record_data_please_quit = TRUE;
    state.record_data_call = TRUE;
    if(pthread_cond_signal(&state.record_data_cond))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }   
    if(pthread_mutex_unlock(&state.record_data_mutex))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    //
    if(pthread_mutex_lock(&state.update_graph_mutex))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    state.update_graph_please_quit = TRUE;
    state.update_graph_call = TRUE;
    if(pthread_cond_signal(&state.update_graph_cond))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    if(pthread_mutex_unlock(&state.update_graph_mutex))
    {
        perror(ERR_MAIN);
        exit(EXIT_FAILURE);
    }
    
    
    // multi-threading end
    pthread_join(state.read_com_th, NULL);
    pthread_join(state.record_data_th, NULL);
    pthread_join(state.update_graph_th, NULL);
    pthread_mutex_destroy(&state.read_com_mutex);
    pthread_mutex_destroy(&state.record_data_mutex);
    pthread_mutex_destroy(&state.update_graph_mutex);
    pthread_cond_destroy(&state.read_com_cond);
    pthread_cond_destroy(&state.record_data_cond);
    pthread_cond_destroy(&state.update_graph_cond);
    
    // free buffers
    free(state.data_buffer[0]);
    free(state.data_buffer[1]);
    // end
    return(EXIT_SUCCESS);
}
