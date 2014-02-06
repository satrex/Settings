/*  Phil's logging library.
 *
 *  Simple to use !
 */


#ifndef PLOG_H
#define PLOG_H

#define PLOG_LEVEL_DEEPDBG  0
#define PLOG_LEVEL_DBG      10
#define PLOG_LEVEL_ERR      30

/**! Main logging class.

  Use me with:
    PLogArea( "some_area" ).dbg( "the number is %d", n );

  It's common to use defines to make the debug code shorter:
    #define dbg   PLogArea( "some_area).dbg
    #define err   PLogArea( "some_area).dbg

    void some_func()
    {
        ...
        dbg( "the number is %d", n ) 
        ...
    }
*/
class PLogArea
{
public:
    PLogArea( const char * p_area, const char * p_funcInfo=0L ) 
        : area( p_area ), funcInfo( p_funcInfo ) 
        { }

    void deepdbg( const char * fmt, ... );    
    void dbg( const char * fmt, ... );    
    void err( const char * fmt, ... );    

    void log( int level, const char * fmt, ... );    

    const char * area;
    const char * funcInfo;
};

#endif // PLOG_H

