
import time, sys
from PyQt4 import QtGui, QtCore

print sys.path

from pyvimwrapper.vimWrapper import VimWrapper
from pyvimwrapper.bufferInfo import *
from pyvimwrapper.tests.const import vimExec
from pyvimwrapper.logSystem import *
from multiVimWidget_ui import Ui_multiVimWidget

dbg = getLogger('MultiVim').debug
err = getLogger('MultiVim').error

class MultiVim( QtGui.QWidget ):
    def __init__(self, *args ):
        QtGui.QWidget.__init__( self, *args )
        self.ui = Ui_multiVimWidget()
        self.ui.setupUi( self )

        self.fileList = []

        self.vw = VimWrapper(vimExec=vimExec)
        self.vw.addEventHandler( self.eventBuffer )
        self.vw.start()
        self.vw.openFile( 'tests/some_file1.txt' )
        self.vw.openFile( 'tests/some_file2.txt' )

        self.timer = QtCore.QTimer(self)
        QtCore.QObject.connect( self.timer, QtCore.SIGNAL('timeout()'), self.slotProcessVimEvents )
        self.timer.start( 1 ) # 0.2 s

        QtCore.QObject.connect( self.ui.evaluateButton, QtCore.SIGNAL('clicked()'), self.slotEvaluate)
        QtCore.QObject.connect( self.ui.tabWidget, QtCore.SIGNAL('currentChanged(int)'), self.slotTabChanged)


    def slotProcessVimEvents(self):
        self.vw.server.processRequest( False )

    def slotEvaluate( self ):
        '''Evaluate the content of the line edit as a python expression.'''
        text = str( self.ui.lineEdit.text() )
        if not len(text): return
        dbg( 'Eval result: ' + str(eval( text )) )
        self.ui.lineEdit.clear()

    def slotAboutToQuit( self ):
        dbg( '...' )
        if self.vw.server.isConnected():
            self.vw.close()
        dbg( 'done' )

    def slotTabChanged( self, tabIdx ):
        dbg( '%d', tabIdx )

    def eventBuffer( self, eventName, eventArgs ):
        '''Called when a buffer is added or deleted.'''
        dbg( '%s %s', eventName, eventArgs )
        bufId, path = eventArgs
        if eventName == EVT_BUFFER_CREATED:
            w = QtGui.QWidget()
            w.path = path
            w.bufId = bufId
            w.tabIdx = self.ui.tabWidget.addTab( w, path )
            self.fileList.append( w )
        elif eventName == EVT_BUFFER_DELETED:
            to_remove = None
            for i,w in enumerate(self.fileList):
                if w.bufId == bufId:
                    to_remove = (i,w)
                    break
            else:
                err( 'Could not find item for bufId %d', bufId )
            (i,w) = to_remove
            self.ui.tabWidget.removeTab( w.tabIdx )
            del self.fileList[i]
        else:
            err( 'Unknown event: %s %s', eventName, eventArgs)




def main():
    initLogSystem( sys.stderr )
    app = QtGui.QApplication(sys.argv)
    mv = MultiVim()
    mv.show()

    QtCore.QObject.connect( app, QtCore.SIGNAL('aboutToQuit()'), mv.slotAboutToQuit )

    sys.exit( app.exec_() )

if __name__ == '__main__': main()
