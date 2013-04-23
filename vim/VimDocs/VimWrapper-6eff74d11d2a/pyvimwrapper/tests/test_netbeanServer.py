
import py
import time, sys, re
sys.path.append( '..' )
sys.path.append( '.' )

from ..vimLauncher import VimLauncher
from ..netbeanServer import NetbeanServer, parseNetbeanArgs, simplifyBackslash, NetbeanProtocolError, packArgs
from ..logSystem import initLogSystem,getLogger

from const import vimExec

dbg = getLogger('test_netbeanServer').debug


class TestNetbeanServer:

    def setup_method(self, m):
        initLogSystem( sys.stderr )
        self.server = None
        self.vl = None

    def teardown_method(self, m):
        if self.server and self.server.isConnected():
            self.server.sendDisconnect()
            self.server.closeServer()

    def testConnection(self):
    
        server = self.server = NetbeanServer()
        server.startServer()
    
        self.vl = vl = VimLauncher( vimExec=vimExec, netbeanPort=server.netbeanPort, netbeanPwd=server.netbeanPwd )
        vl.startVim()
        assert vl.isVimRunning() 
   
        server.waitForConnection()
        assert server.isConnected()

        server.waitStartupDone()    

        assert server.authDone
        assert server.startupDone

        # now vim is sending nothing, check that non-blocking wait works.
        assert server.processRequest(False) == 0
        assert server.processRequest(False) == 0
        assert server.processRequest(False) == 0
        assert server.processRequest(False) == 0
        assert server.processRequest(False) == 0

        assert server.pingConnection() == True

    def testUseReply( self ):
        server = self.server = NetbeanServer()
        server.startServer()
    
        self.vl = vl = VimLauncher( vimExec=vimExec, netbeanPort=server.netbeanPort, netbeanPwd=server.netbeanPwd )
        vl.startVim()
        assert vl.isVimRunning() 
   
        server.waitForConnection()
        assert server.isConnected()

        server.processRequest(True) # auth
        server.processRequest(True) # version
        server.processRequest(True) # startup

        # raw exchange
        s = server.sendCmdWithReply( 0, 'getCursor' )
        assert s == '-1 1 0 0'

        # create a buffer
        self.server.sendCmd( 1, 'create' )

        s = server.sendCmdWithReply( 1, 'getLength' )
        assert s == '0'

        # high level exchange
        ret = server.call( 0, 'getCursor', 'NUM NUM NUM NUM' )
        assert ret == (1, 1, 0, 0)

        ret = server.call( 1, 'getLength', 'NUM' )
        assert ret == (0,)

        assert server.pingConnection() == True

        py.test.raises( NetbeanProtocolError, server.call, 1, 'getLength', 'STR' )
        py.test.raises( NetbeanProtocolError, server.call, 1, 'getLength', 'NUM NUM' )


    def testPingConnection( self ):
        server = self.server = NetbeanServer()
        server.startServer()
    
        self.vl = vl = VimLauncher( vimExec=vimExec, netbeanPort=server.netbeanPort, netbeanPwd=server.netbeanPwd )
        vl.startVim()
        assert vl.isVimRunning() 
   
        server.waitForConnection()
        assert server.isConnected()

        server.processRequest(True) # auth
        server.processRequest(True) # version
        server.processRequest(True) # startup

        assert server.pingConnection() == True
        self.server.sendDisconnect()
        assert server.pingConnection() == False
        self.server.closeServer()
        assert server.pingConnection() == False



