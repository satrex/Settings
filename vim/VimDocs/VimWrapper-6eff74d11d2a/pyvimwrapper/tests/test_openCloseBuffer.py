
import py, os.path, sys, time
sys.path.append( '..' )
sys.path.append( '.' )

from ..vimWrapper import VimWrapper
from ..logSystem import initLogSystem,getLogger,Win32DebugStream

from const import *

dbg = getLogger('test_openCloseBuffer').debug

vw = None

STOP_BEFORE_EXIT = 0

class TestOpenCloseBuffer:

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
        vw.createBuffer( TESTFILE1 )
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

    def testOpenCloseBuffer( self ):
        bufId1 = vw.getBufId()
        bufId2 = vw.createBuffer( TESTFILE2 )
        bufId3 = vw.createBuffer( TESTFILE3 )
        assert bufId3 > bufId2 > bufId1

        assert vw.bufInfo.bufIdOfPath( TESTFILE1 ) == bufId1
        assert vw.bufInfo.bufIdOfPath( TESTFILE2 ) == bufId2
        assert vw.bufInfo.bufIdOfPath( TESTFILE3 ) == bufId3
        assert vw.bufInfo.bufferNb() == 3

        vw.insertText( bufId1, 'abc', 0 )        
        assert vw.getBufId() == 1
        vw.insertText( bufId2, 'def', 0 )        
        # insert is supposed to adjust the current buffer
        assert vw.getBufId() == 2
        vw.insertText( bufId3, 'ghi', 0 )        
        assert vw.getBufId() == 3

        assert vw.text( bufId1 ) == 'abc\n'
        assert vw.text( bufId2 ) == 'def\n'
        assert vw.text( bufId3 ) == 'ghi\n'

        
    def testOpenCloseBuffer2( self ):
        bufId1 = vw.getBufId()
        bufId2 = vw.createBuffer( TESTFILE2 )
        bufId3 = vw.createBuffer( TESTFILE3 )
        assert bufId3 > bufId2 > bufId1

        assert vw.bufInfo.bufIdOfPath( TESTFILE1 ) == bufId1
        assert vw.bufInfo.bufIdOfPath( TESTFILE2 ) == bufId2
        assert vw.bufInfo.bufIdOfPath( TESTFILE3 ) == bufId3
        assert vw.bufInfo.bufferNb() == 3

        vw.insertText( bufId1, 'abc', 0 )        
        vw.insertText( bufId2, 'def', 0 )        
        vw.insertText( bufId3, 'ghi', 0 )        

        vw.server.sendCmd( bufId1, 'setVisible', True ) 
        assert vw.getBufId() == 1
        vw.server.sendCmd( bufId2, 'setVisible', True ) 
        assert vw.getBufId() == 2
        vw.server.sendCmd( bufId3, 'setVisible', True ) 
        assert vw.getBufId() == 3


    def testCreateCloseBuffer( self ):
        bufId1 = vw.getBufId()
        bufId2 = vw.createBuffer( TESTFILE2 )
        bufId3 = vw.createBuffer( TESTFILE3 )
        assert bufId3 > bufId2 > bufId1

        assert vw.bufInfo.bufIdOfPath( TESTFILE1 ) == bufId1
        assert vw.bufInfo.bufIdOfPath( TESTFILE2 ) == bufId2
        assert vw.bufInfo.bufIdOfPath( TESTFILE3 ) == bufId3
        assert vw.bufInfo.bufferNb() == 3

        vw.insertText( bufId1, 'abc', 0 )        
        assert vw.text( bufId1 ) == 'abc\n'

        vw.insertText( bufId2, 'def', 0 )        
        assert vw.text( bufId1 ) == 'abc\n'
        assert vw.text( bufId2 ) == 'def\n'

        vw.insertText( bufId3, 'ghi', 0 )        
        assert vw.text( bufId1 ) == 'abc\n'
        assert vw.text( bufId2 ) == 'def\n'
        assert vw.text( bufId3 ) == 'ghi\n'

        vw.setCurrentBuffer( bufId1 )
        assert vw.getBufId() == 1
        vw.setCurrentBuffer( bufId2 )
        assert vw.getBufId() == 2

        assert vw.closeBuffer( bufId2 ) == None
        assert vw.bufInfo.bufIdOfPath( TESTFILE1 ) == bufId1
        assert vw.bufInfo.bufIdOfPath( TESTFILE3 ) == bufId3
        py.test.raises( IndexError, vw.bufInfo.bufIdOfPath, TESTFILE2 )
        py.test.raises( IndexError, vw.bufInfo.pathOfBufId, bufId2 )
        assert vw.bufInfo.bufferNb() == 2

        assert vw.getBufId() == 3
        vw.setCurrentBuffer( bufId1 )
        assert vw.getBufId() == 1

        assert vw.closeBuffer( bufId1 ) == None
        assert vw.bufInfo.bufIdOfPath( TESTFILE3 ) == bufId3
        py.test.raises( IndexError, vw.bufInfo.bufIdOfPath, TESTFILE2 )
        py.test.raises( IndexError, vw.bufInfo.pathOfBufId, bufId2 )
        py.test.raises( IndexError, vw.bufInfo.bufIdOfPath, TESTFILE1 )
        py.test.raises( IndexError, vw.bufInfo.pathOfBufId, bufId1 )
        assert vw.bufInfo.bufferNb() == 1

        assert vw.getBufId() == 3

    def testOpenExistingFile( self ):
        open( TESTFILE2, 'w').write( 'coucou\n' )
        assert open( TESTFILE2 ).read() == 'coucou\n' 

        bufId1 = vw.getBufId()
        assert vw.bufInfo.bufferNb() == 1

        vw.openFile( TESTFILE2 )
        vw.processVimEvents()
        assert vw.bufInfo.bufferNb() == 2
        bufId2 = vw.bufInfo.nextBuffer( bufId1 )
        assert bufId2 != bufId1
        path2 = vw.bufInfo.pathOfBufId( bufId2 )
        assert os.path.abspath( TESTFILE2 ) == os.path.abspath( path2 )
        assert vw.text( bufId2 ) == 'coucou\n'
        assert vw.bufInfo.bufferNb() == 2

    def testOpenFile( self ):

        bufId1 = vw.getBufId()
        assert vw.bufInfo.bufferNb() == 1

        bufId2 = vw.bufInfo.createBufId()
        vw.bufInfo.addBuffer( bufId2, TESTFILE2 )
        vw.server.sendCmd( bufId2, 'editFile', TESTFILE2 )
        vw.processVimEvents()

        assert vw.getBufId() == bufId2 

        vw.setCurrentBuffer( bufId1 )
        assert vw.getBufId() == bufId1

        vw.setCurrentBuffer( bufId2 )
        assert vw.getBufId() == bufId2 

    def testCreateExistingFile( self ):
        open( TESTFILE4, 'w').write( 'coucou\n' )
        assert open( TESTFILE4 ).read() == 'coucou\n' 

        assert vw.bufInfo.bufferNb() == 1

        bufId2 = vw.createBuffer( TESTFILE4 )
        path2 = vw.bufInfo.pathOfBufId( bufId2 )
        assert os.path.abspath( TESTFILE4 ) == os.path.abspath( path2 )
        # file should be empty !
        assert vw.text( bufId2 ) == '\n'
        assert vw.bufInfo.bufferNb() == 2

    def testSetCurrentBuffer( self ):
        open( TESTFILE2, 'w').write( 'coucou\n' )
        assert open( TESTFILE2 ).read() == 'coucou\n' 

        bufId1 = vw.getBufId()
        assert vw.bufInfo.bufferNb() == 1

        vw.openFile( TESTFILE2 )
        vw.processVimEvents()
        assert vw.bufInfo.bufferNb() == 2
        bufId2 = vw.bufInfo.nextBuffer( bufId1 )
        assert bufId2 != bufId1
        path2 = vw.bufInfo.pathOfBufId( bufId2 )
        assert os.path.abspath( TESTFILE2 ) == os.path.abspath( path2 )
        assert vw.text( bufId2 ) == 'coucou\n'
        assert vw.bufInfo.bufferNb() == 2

        assert vw.getBufId() == bufId2
        vw.setCurrentBuffer( bufId1 )
        assert vw.getBufId() == bufId1

        vw.setCurrentBufferLineCol( 2, 1, 3 )
        assert vw.getBufId() == bufId2
        assert vw.getCursorLineCol() == (1,3)

        vw.setCurrentBuffer( bufId1 )
        assert vw.getBufId() == bufId1

        vw.setCurrentBufferOffset( 2, 5 )
        assert vw.getBufId() == bufId2
        assert vw.getCursorOffset() == 5


    def testUserAddsBuffer( self ):
        bufId1 = vw.getBufId()

        vw.sendKeysNormalMode( ':e %s\n' % TESTFILE2 )
        vw.processVimEvents( )

        dbg( 'bufInfo = %s', str(vw.bufInfo) )

        assert vw.bufInfo.bufIdOfPath( TESTFILE1 ) == bufId1
        bufId2 = vw.bufInfo.nextBuffer( bufId1 )
        path2 = vw.bufInfo.pathOfBufId( bufId2 )
        assert os.path.abspath( TESTFILE2 ) == os.path.abspath( path2 )
        assert vw.bufInfo.bufferNb() == 2

        vw.insertText( bufId1, 'abc', 0 )        
        assert vw.text( bufId1 ) == 'abc\n'

        vw.insertText( bufId2, 'def', 0 )        
        assert vw.text( bufId1 ) == 'abc\n'
        assert vw.text( bufId2 ) == 'def\n'

        vw.setCurrentBuffer( bufId1 )
        assert vw.getBufId() == bufId1
        vw.setCurrentBuffer( bufId2 )
        assert vw.getBufId() == bufId2

    def testUserClosesBuffer( self ):
        bufId1 = vw.getBufId()
        assert vw.bufInfo.bufIdOfPath( TESTFILE1 ) == bufId1

        vw.sendKeysNormalMode( ':e %s\n' % TESTFILE2 )
        vw.processVimEvents()
        bufId2 = vw.bufInfo.nextBuffer( bufId1 )
        path2 = vw.bufInfo.pathOfBufId( bufId2 )
        assert os.path.abspath( TESTFILE2 ) == os.path.abspath( path2 )
        assert vw.bufInfo.bufferNb() == 2

        bufId3 = vw.openFile( TESTFILE3 )
        path3 = vw.bufInfo.pathOfBufId( bufId3 )
        assert os.path.abspath( TESTFILE3 ) == os.path.abspath( path3 )
        assert vw.bufInfo.bufferNb() == 3

        bufId4 = vw.openFile( TESTFILE4 )
        path4 = vw.bufInfo.pathOfBufId( bufId4 )
        assert os.path.abspath( TESTFILE4 ) == os.path.abspath( path4 )
        assert vw.bufInfo.bufferNb() == 4

        assert vw.getBufId() == bufId4
        vw.sendKeysNormalMode( ':bd\n' )
        vw.processVimEvents()

        assert vw.bufInfo.bufferNb() == 3
        assert vw.getBufId() == bufId1

        vw.closeBuffer( bufId2 )
        assert vw.getBufId() == bufId1
        assert vw.bufInfo.bufferNb() == 2
        assert vw.bufInfo.nextBuffer( bufId1 ) == bufId3

        vw.closeBuffer( bufId1 )
        assert vw.bufInfo.bufferNb() == 1
        assert vw.getBufId() == bufId3

    def testUserSwitchesBuffer( self ):
        bufId1 = vw.getBufId()
        assert vw.bufInfo.bufIdOfPath( TESTFILE1 ) == bufId1

        vw.sendKeysNormalMode( ':e %s\n' % TESTFILE2 )
        vw.processVimEvents()
        bufId2 = vw.bufInfo.nextBuffer( bufId1 )
        path2 = vw.bufInfo.pathOfBufId( bufId2 )
        assert os.path.abspath( TESTFILE2 ) == os.path.abspath( path2 )
        assert vw.bufInfo.bufferNb() == 2

        bufId3 = vw.openFile( TESTFILE3 )
        path3 = vw.bufInfo.pathOfBufId( bufId3 )
        assert os.path.abspath( TESTFILE3 ) == os.path.abspath( path3 )
        assert vw.bufInfo.bufferNb() == 3

        dbg( 'bufInfo = %s', str(vw.bufInfo) )

        assert vw.getBufId() == bufId3
        vw.sendKeysNormalMode( ':bn\n')
        assert vw.getBufId() == bufId1

        vw.sendKeysNormalMode( ':bn\n')
        assert vw.getBufId() == bufId2

        vw.sendKeysNormalMode( ':bn\n')
        assert vw.getBufId() == bufId3

        vw.sendKeysNormalMode( ':bf\n')
        assert vw.getBufId() == bufId1

        vw.sendKeysNormalMode( ':bl\n')
        assert vw.getBufId() == bufId3

        vw.sendKeysNormalMode( ':buffer %s\n' % TESTFILE1 )
        assert vw.getBufId() == bufId1

        vw.sendKeysNormalMode( ':buffer %s\n' % TESTFILE2 )
        assert vw.getBufId() == bufId2
        
        vw.sendKeysNormalMode( ':buffer %s\n' % TESTFILE3 )
        assert vw.getBufId() == bufId3
       
        vw.sendKeysNormalMode( ':buffer %s\n' % os.path.abspath( TESTFILE1 ) )
        assert vw.getBufId() == bufId1

        vw.sendKeysNormalMode( ':buffer %s\n' % os.path.abspath( TESTFILE2 ) )
        assert vw.getBufId() == bufId2
        
        vw.sendKeysNormalMode( ':buffer %s\n' % os.path.abspath( TESTFILE3 ) )
        assert vw.getBufId() == bufId3
       

 
