
import time
import os
import py.test

from ..vimLauncher import VimLauncher, VimLauncherError
from ..logSystem import initLogSystem
from const import vimExec

class TestVimLauncher:

    def setup_method(self, m):
        initLogSystem()
        self.vl = None

    def teardown_method(self, m):
        if self.vl:
            self.vl.shutDown()
            self.vl = None

    def testStartVim(self):
        self.vl = VimLauncher( vimExec = vimExec )
        self.vl.useNetbean = False
        assert self.vl.isVimRunning() == False
        self.vl.startVim()
        assert self.vl.isVimRunning() == True


    def testShutdown(self):
        self.vl = VimLauncher( vimExec = vimExec )
        self.vl.useNetbean = False
        assert self.vl.isVimRunning() == False

        # no exception raised
        self.vl.shutDown()

        # startit
        self.vl.startVim()
        assert self.vl.isVimRunning() == True

        # shut it down twice
        self.vl.shutDown()
        time.sleep( 1 )
        self.vl.shutDown()


    def testSendKeysVimNotRunning(self):
        self.vl = VimLauncher( vimExec = vimExec )
        self.vl.useNetbean = False
        assert self.vl.isVimRunning() == False

        py.test.raises( VimLauncherError, self.vl.sendKeys, 'inothing' )

        self.vl.startVim()
        self.vl.sendKeys( 'inothing' )
        self.vl.shutDown()

        py.test.raises( VimLauncherError, self.vl.sendKeys, 'inothing' )


    def XtestExpr(self):
        self.vl = VimLauncher( vimExec = vimExec )
        self.vl.useNetbean = False
        self.vl.startVim()

        response = self.vl.evalExpr( '1+2' )

        assert response == '3\n'



