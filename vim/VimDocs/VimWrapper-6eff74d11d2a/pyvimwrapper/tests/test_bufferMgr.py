
import py
import sys
sys.path.append( '..' )
sys.path.append( '.' )

from ..bufferMgr import BufferMgr, EVT_BUFFER_CREATED, EVT_BUFFER_DELETED
from ..logSystem import initLogSystem,getLogger,Win32DebugStream

dbg = getLogger('test_bufferMgr').debug


class TestBufferMgr:

    def testAddBuffer( self ):
        bi = BufferMgr()

        assert bi.firstBufId() == None

        bufId = bi.createBufId()
        bi.addBuffer( bufId, 'toto' )
        assert bi.bufIdOfPath( 'toto' ) == bufId
        assert bi.pathOfBufId( bufId ) == 'toto'
        assert bi.hasBufId( bufId )
        assert bi.hasPath( 'toto' )
        assert bi.bufferNb() == 1
        
        assert bi.firstBufId() == bufId

        bufId = bi.createBufId()
        bi.addBuffer( bufId, 'titi' )
        assert bi.bufIdOfPath( 'titi' ) == bufId
        assert bi.pathOfBufId( bufId ) == 'titi'
        assert bi.hasBufId( bufId )
        assert bi.hasPath( 'titi' )
        assert bi.bufferNb() == 2

        bufId = bi.createBufId()
        bi.addBuffer( bufId, 'tata' )
        assert bi.bufIdOfPath( 'tata' ) == bufId
        assert bi.pathOfBufId( bufId ) == 'tata'
        assert bi.hasBufId( bufId )
        assert bi.hasPath( 'tata' )
        assert bi.bufferNb() == bufId

        py.test.raises( IndexError, bi.pathOfBufId, bufId+1 )
        py.test.raises( IndexError, bi.bufIdOfPath, '' )
        assert bi.hasBufId( bufId+1 ) == False
        assert bi.hasPath( '' ) == False

        assert bi.nextBuffer( 1 ) == 2
        assert bi.nextBuffer( 2 ) == 3
        assert bi.nextBuffer( 3 ) == 1

        bi.rmBufferByBufId( 2 )
        py.test.raises( IndexError, bi.pathOfBufId, 2 )
        py.test.raises( IndexError, bi.bufIdOfPath, 'titi' )
        assert bi.hasBufId( 2 ) == False
        assert bi.hasPath( 'titi' ) == False
        assert bi.bufferNb() == 2

        assert bi.bufIdOfPath( 'toto' ) == 1
        assert bi.pathOfBufId( 1 ) == 'toto'
        assert bi.hasBufId( 1 )
        assert bi.hasPath( 'toto' )
        
        assert bi.bufIdOfPath( 'tata' ) == 3
        assert bi.pathOfBufId( 3 ) == 'tata'
        assert bi.hasBufId( 3 )
        assert bi.hasPath( 'tata' )

        assert bi.nextBuffer( 1 ) == 3
        assert bi.nextBuffer( 3 ) == 1

        assert bi.bufferNb() == 2

        bufId = bi.bufIdOfPath( 'toto' )
        assert bi.addBuffer( bufId, 'toto' ) == bufId
        assert bi.bufferNb() == 2

    def testEventStuff( self ):

        bi = BufferMgr()

        self.eventsList = []        
        def hlr(*args): self.eventsList.append( args )
        bi.addEventHandler( hlr )

        assert len(self.eventsList) == 0

        bufId = bi.createBufId()
        bi.addBuffer( bufId, 'toto' )
        assert len(self.eventsList) == 1
        assert self.eventsList[0] == (EVT_BUFFER_CREATED, (1,'toto') )

        bufId = bi.createBufId()
        bi.addBuffer( bufId, 'titi' )
        assert len(self.eventsList) == 2
        assert self.eventsList[1] == (EVT_BUFFER_CREATED, (2,'titi') )

        # nothing happens
        bufId = bi.createBufId()
        bufId2 = bi.addBuffer( bufId, 'titi' )
        assert len(self.eventsList) == 2

        bi.rmBufferByBufId( bufId2 )
        assert self.eventsList[2] == (EVT_BUFFER_DELETED, (2,'titi') )
        assert len(self.eventsList) == 3




