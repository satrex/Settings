
import py, os.path, sys, time
sys.path.append( '..' )
sys.path.append( '.' )

from ..vimWrapper import VimWrapper
from ..logSystem import initLogSystem,getLogger,Win32DebugStream

from const import *

dbg = getLogger('test_saveAndModified').debug

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
        if STOP_BEFORE_EXIT: raw_input('[Press enter]')
        if vw and vw.server and vw.server.isConnected():
            vw.close()
    
        FILELIST = [ TESTFILE1, TESTFILE2, TESTFILE3, TESTFILE4 ]
        for f in FILELIST:
            if os.path.exists( f ):
                os.remove( f )
        dbg( 'done' )

    def testModified( self ):
        dbg('...')
        bufId1 = vw.getBufId()

        assert vw.isBufferModified( bufId1 ) == False

        vw.insertText( bufId1, 0, 'buffer1' )
        assert vw.text( bufId1 ) == 'buffer1\n'
        vw.removeText( bufId1, 3, 3 )
        assert vw.text( bufId1 ) == 'buf1\n'

        assert vw.isBufferModified( bufId1 ) ==  False
        vw.setModified( bufId1, True )
        assert vw.isBufferModified( bufId1 ) ==  True

    def testSaveModifiedByNetbeans( self ):
        dbg('...')
        assert os.path.exists( TESTFILE1 ) == False
        bufId1 = vw.getBufId()

        assert vw.isBufferModified( bufId1 ) == False

        vw.insertText( bufId1, 0, 'buffer1' )
        assert vw.text( bufId1 ) == 'buffer1\n'
        vw.removeText( bufId1, 3, 3 )
        assert vw.text( bufId1 ) == 'buf1\n'
        assert vw.isBufferModified( bufId1 ) ==  False

        vw.saveBuffer( bufId1 )
        vw.processVimEvents()
        assert os.path.exists( TESTFILE1 ) == False
        assert vw.isBufferModified( bufId1 ) == False

        vw.setModified( bufId1, True )
        assert vw.isBufferModified( bufId1 ) ==  True

        vw.saveBuffer( bufId1 )
        vw.processVimEvents()
        assert os.path.exists( TESTFILE1 ) == True
        assert open( TESTFILE1 ).read() == 'buf1\n' 
        assert vw.isBufferModified( bufId1 ) == False
        

    def testSaveModifiedByVim( self ):
        dbg('...')
        assert os.path.exists( TESTFILE1 ) == False
        bufId1 = vw.getBufId()

        assert vw.isBufferModified( bufId1 ) == False

        vw.sendKeysNormalMode( 'ibuffer1<ESC>' )
        assert vw.text( bufId1 ) == 'buffer1\n'
        assert vw.isBufferModified( bufId1 ) ==  True

        vw.saveBuffer( bufId1 )
        vw.processVimEvents()
        assert os.path.exists( TESTFILE1 ) == True
        assert open( TESTFILE1 ).read() == 'buffer1\n' 
        assert vw.isBufferModified( bufId1 ) == False
        







