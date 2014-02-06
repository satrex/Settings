
#include "plog.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

void plogLog( int level, const char * area, const char * funcInfo, const char * fmt, va_list args );

void PLogArea::log( int level, const char * fmt, ... )
{
    va_list ap;
    va_start( ap, fmt );
    plogLog( level, area, funcInfo, fmt, ap );
    va_end( ap );
}

void PLogArea::deepdbg( const char * fmt, ... )
{
    va_list ap;
    va_start( ap, fmt );
    plogLog( PLOG_LEVEL_DEEPDBG, area, funcInfo, fmt, ap );
    va_end( ap );
    
}

void PLogArea::dbg( const char * fmt, ... )    
{
    va_list ap;
    va_start( ap, fmt );
    plogLog( PLOG_LEVEL_DBG, area, funcInfo, fmt, ap );
    va_end( ap );
    
}

void PLogArea::err( const char * fmt, ... )    
{
    va_list ap;
    va_start( ap, fmt );
    plogLog( PLOG_LEVEL_ERR, area, funcInfo, fmt, ap );
    va_end( ap );
    
}

void plogOutput( const char * buf )
{
    fprintf( stderr, buf );    
}
    
void plogLog( int level, const char * area, const char * funcInfo, const char * fmt, va_list args )
{
    char buf[ 1024 ];
    char buf2[ 1024 ];

    // if area accepts log level
    // if log level accepts log level
    
    vsnprintf( buf, 1024, fmt, args );
    if (funcInfo != 0L) {
        snprintf( buf2, 1024, "%10s.%-10s %s", area, funcInfo, buf );
    } else {
        snprintf( buf2, 1024, "%10s %s", area, buf );
    }
    int sz=strlen(buf2);
    if (sz && buf2[sz-1] != '\n' && sz<1024) strcat( buf2, "\n" );
    plogOutput( buf2 );
}

