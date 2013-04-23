
#ifndef QVIMLAUNCHER_H
#define QVIMLAUNCHER_H


#define dbg PLogArea( "QVimLauncher" ).dbg
#define err PLogArea( "QVimLauncher" ).err

class VimLauncher {
    VimLauncher();

    def __init__(self, **kwargs):
        '''Init the vim launcher.

        Keyword arguments: 
        - vimExec: path the vim executable file
        - netbeanPwd: netbean password. If not provided, generated on the fly.
        - netbeanPort: port number of the netbean server. Default to 5678
        - netbeanHost: host on which the netbean server is running. Default to localhost.
        - useNetbean:  connect to a netbean host on startup
        '''
    def findVimExecutable( self ):
        '''Try to locate the vim executable on the path.'''

    def startVim( self ):

    def isVimRunning( self ):

    def sendKeys( self, keys ):

    def sendKeysNormalMode( self, keys ):

    def evalExpr( self, expr ):

    def shutDown( self ):
        '''Ask vim to quit.'''






#endif // QVIMLAUNCHER_H
