

import py, os.path, sys, time
sys.path.append( '..' )
sys.path.append( '.' )

from ..vimWrapper import VimWrapper
from ..logSystem import initLogSystem,getLogger,Win32DebugStream

from const import *

dbg = getLogger('test_specialKeys').debug

vw = None

STOP_BEFORE_EXIT = 0

class TestSaveAndModified:

    def setup_class(cls):
       
        initLogSystem( sys.stderr )
        if os.path.exists( VIM_NETBEANS_LOG ): 
            try:
                os.remove( VIM_NETBEANS_LOG )
            except: pass
        dbg( 'done' )

    def Xteardown_class(cls):
        dbg( 'done' )

    def setup_method( self, m ):
        global vw
        vw = VimWrapper( vimExec=vimExec )
        vw.start()
        bufId1 = vw.createBuffer( TESTFILE1 )
        dbg( 'done' )

    def teardown_method( self, m ):
        dbg( '...')
        vw.processVimEvents()
        if STOP_BEFORE_EXIT: raw_input('[Press enter]')
        if vw and vw.server and vw.server.isConnected():
            vw.close()
    
        FILELIST = [ TESTFILE1, TESTFILE2, TESTFILE3, TESTFILE4 ]
        for f in FILELIST:
            if os.path.exists( f ):
                os.remove( f )
        dbg( 'done' )

    def XtestSpecialKeys1( self ):
        # not working...
        dbg('...')
        vw.sendKeysNormalMode( ':map <F4> icoucou<lt>ESC>\n' )

        bufId1 = vw.bufInfo.firstBufId()
        assert vw.text( bufId1 ) == '\n'
        vw.sendKeys( '<F4>' )
        assert vw.text( bufId1 ) == 'coucou\n'

    def testSpecialKeys2( self ):
        dbg('...')

        vw.insertText( 1, 0, 'abc\ndef' )
        vw.setCurrentBufferLineCol( 1, 2, 1 )
        assert vw._getCursor() == (1, 2, 1, 5 )
        text = 'abc\ndef\n'

        l = []
        def eventListener( name, args ):
            l.append( (name, args ) )
        vw.addEventHandler( eventListener )

        assert l == []
        vw.setSpecialKeys( '<F4>' )        
        bufId1 = vw.bufInfo.firstBufId()
        assert vw.text( bufId1 ) == text
        vw.sendKeys( '<F4>' )
        assert vw.text( bufId1 ) == text

        vw.sendKeys( '<F21><F4>' )
        assert vw.text( bufId1 ) == text
        assert l == [ ('Hotkey', (1, 'F4', 5, (2,1) )) ]

        bufId, key, offset, (line,col) = l[0][1]
        assert vw._getCursor() == (bufId, line, col, offset)

        vw.setCurrentBufferLineCol( 1, 1, 1 )
        vw.sendKeysNormalMode( ':nbkey F4<CR>' )
        vw.processVimEvents()

        assert l[1] == ('Hotkey', (1, 'F4', 1, (1,1) ))
        assert len(l) == 2

        vw.setCurrentBufferLineCol( 1, 2, 2 )
        vw.sendKeysNormalMode( ':nbkey X<CR>' )
        vw.processVimEvents()

        assert l[2] == ('Hotkey', (1, 'X', 6, (2,2) ))
        assert len(l) == 3

