
import py
import sys
sys.path.append( '..' )
sys.path.append( '.' )

from ..vimWrapper import VimWrapper
from ..logSystem import initLogSystem,getLogger,Win32DebugStream

from const import *

dbg = getLogger('test_vimWrapper').debug

vw = None

STOP_BEFORE_EXIT = 0

class TestNetbeanServer:

    def setup_class(cls):
        initLogSystem( sys.stderr )
        dbg( '...')
        global vw
        initLogSystem()
        vw = VimWrapper( vimExec=vimExec )
        vw.start()
        vw.createBuffer( TESTFILE1 )
        dbg( 'done' )

    def teardown_class(cls):
        dbg( '...' )
        if STOP_BEFORE_EXIT: raw_input('[Press enter]')
        if vw and vw.server and vw.server.isConnected():
            vw.close()
        dbg( 'done' )

    def setup_method( self, m ):
        # clear the buffer
        bufId = vw.getBufId()
        assert bufId == 1
        assert vw.getLength( bufId ) == 0
        dbg( 'done' )

    def teardown_method( self, m ):
        dbg( '...')

        # close all buffers but buffer 1
        for i in range( 1, vw.bufInfo.bufferNb() ):
            vw.closeBuffer( vw.bufInfo.bufInfo[i][0] )
        assert vw.bufInfo.bufferNb() == 1
        vw.processVimEvents()

        # Empty buffer 1
        bufId = 1
        length = vw.getLength( bufId )
        if length > 0:
            dbg( 'Clearing the buffer' )
            vw.sendKeysNormalMode( 'ggdG' )
            assert vw.getLength( bufId ) == 0
        vw.processVimEvents()

        dbg( 'done' )

    def testGetCursor(self):
        assert vw._getCursor() == (1, 1, 0, 0)
        assert vw.getCursorLine() == 1
        assert vw.getCursorCol() == 0
        assert vw.getCursorOffset() == 0
        assert vw.getBufId() == 1

    def testGetLength( self ):
        assert vw.getLength( vw.getBufId() ) == 0
        # insert some text
        # check that length is modified



        
        
