
import py
import sys
sys.path.append( '..' )
sys.path.append( '.' )

from ..vimWrapper import VimWrapper
from ..logSystem import initLogSystem,getLogger

from const import *

dbg = getLogger('test_vimWrapper').debug

vw = None

STOP_BEFORE_EXIT = 0

class TestNetbeanServer:

    def setup_class(cls):
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
        bufId = vw.getBufId()
        assert bufId == 1
        assert vw.getLength( bufId ) == 0
        dbg( 'done' )

    def teardown_method( self, m ):
        dbg( '...')
        bufId = 1
        length = vw.getLength( bufId )
        if length > 0:
            dbg( 'Clearing the buffer' )
            vw.sendKeysNormalMode( 'ggdG' )
            assert vw.getLength( bufId ) == 0
        vw.processVimEvents()
        dbg( 'done' )


    def testInsertRemoveText0_3( self ):
        bufId = vw.getBufId()
        assert vw.text( bufId ) == '\n'
        assert vw.insertText( bufId, 0, 'abc\ndef\n' ) == None
        assert vw.text( bufId ) == 'abc\ndef\n'

        assert vw.removeText( bufId, 0, 3 ) == None
        assert vw.text( bufId ) == '\ndef\n'

    def testInsertRemoveText0_4( self ):
        bufId = vw.getBufId()
        assert vw.text( bufId ) == '\n'
        assert vw.insertText( bufId, 0, 'abc\ndef\n' ) == None
        assert vw.text( bufId ) == 'abc\ndef\n'

        assert vw.removeText( bufId, 0, 4 ) == None
        assert vw.text( bufId ) == 'def\n'

    def testInsertRemoveText0_5( self ):
        bufId = vw.getBufId()
        assert vw.text( bufId ) == '\n'
        assert vw.insertText( bufId, 0, 'abc\ndef\n' ) == None
        assert vw.text( bufId ) == 'abc\ndef\n'

        assert vw.removeText( bufId, 0, 5 ) == None
        assert vw.text( bufId ) == 'ef\n'

    def testInsertRemoveText0_6( self ):
        bufId = vw.getBufId()
        assert vw.text( bufId ) == '\n'
        assert vw.insertText( bufId, 0, 'abc\ndef\n' ) == None
        assert vw.text( bufId ) == 'abc\ndef\n'

        assert vw.removeText( bufId, 0, 6 ) == None
        assert vw.text( bufId ) == 'f\n'

    def testInsertRemoveText1_2( self ):
        bufId = vw.getBufId()
        assert vw.text( bufId ) == '\n'
        assert vw.insertText( bufId, 0, 'abc\ndef\n' ) == None
        assert vw.text( bufId ) == 'abc\ndef\n'

        assert vw.removeText( bufId, 1, 2 ) == None
        assert vw.text( bufId ) == 'a\ndef\n'

    def testInsertRemoveText1_3( self ):
        bufId = vw.getBufId()
        assert vw.text( bufId ) == '\n'
        assert vw.insertText( bufId, 0, 'abc\ndef\n' ) == None
        assert vw.text( bufId ) == 'abc\ndef\n'

        assert vw.removeText( bufId, 1, 3 ) == None
        assert vw.text( bufId ) == 'adef\n'

    def testInsertRemoveText1_4( self ):
        bufId = vw.getBufId()
        assert vw.text( bufId ) == '\n'
        assert vw.insertText( bufId, 0, 'abc\ndef\n' ) == None
        assert vw.text( bufId ) == 'abc\ndef\n'

        assert vw.removeText( bufId, 1, 4 ) == None
        assert vw.text( bufId ) == 'aef\n'

    def testInsertRemoveText1_5( self ):
        bufId = vw.getBufId()
        assert vw.text( bufId ) == '\n'
        assert vw.insertText( bufId, 0, 'abc\ndef\n' ) == None
        assert vw.text( bufId ) == 'abc\ndef\n'

        assert vw.removeText( bufId, 1, 5 ) == None
        assert vw.text( bufId ) == 'af\n'

