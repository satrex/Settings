# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'multiVimWidget.ui'
#
# Created: Thu May 22 13:18:12 2008
#      by: PyQt4 UI code generator 4.3.3
#
# WARNING! All changes made in this file will be lost!

from PyQt4 import QtCore, QtGui

class Ui_multiVimWidget(object):
    def setupUi(self, multiVimWidget):
        multiVimWidget.setObjectName("multiVimWidget")
        multiVimWidget.resize(QtCore.QSize(QtCore.QRect(0,0,855,450).size()).expandedTo(multiVimWidget.minimumSizeHint()))

        self.vboxlayout = QtGui.QVBoxLayout(multiVimWidget)
        self.vboxlayout.setObjectName("vboxlayout")

        self.tabWidget = QtGui.QTabWidget(multiVimWidget)
        self.tabWidget.setObjectName("tabWidget")

        self.tab = QtGui.QWidget()
        self.tab.setObjectName("tab")
        self.tabWidget.addTab(self.tab,"")

        self.tab_2 = QtGui.QWidget()
        self.tab_2.setObjectName("tab_2")
        self.tabWidget.addTab(self.tab_2,"")
        self.vboxlayout.addWidget(self.tabWidget)

        self.hboxlayout = QtGui.QHBoxLayout()
        self.hboxlayout.setObjectName("hboxlayout")

        self.label_2 = QtGui.QLabel(multiVimWidget)
        self.label_2.setObjectName("label_2")
        self.hboxlayout.addWidget(self.label_2)

        self.lineEdit = QtGui.QLineEdit(multiVimWidget)
        self.lineEdit.setObjectName("lineEdit")
        self.hboxlayout.addWidget(self.lineEdit)

        self.evaluateButton = QtGui.QPushButton(multiVimWidget)
        self.evaluateButton.setObjectName("evaluateButton")
        self.hboxlayout.addWidget(self.evaluateButton)
        self.vboxlayout.addLayout(self.hboxlayout)

        self.retranslateUi(multiVimWidget)
        self.tabWidget.setCurrentIndex(0)
        QtCore.QObject.connect(self.lineEdit,QtCore.SIGNAL("returnPressed()"),self.evaluateButton.click)
        QtCore.QMetaObject.connectSlotsByName(multiVimWidget)

    def retranslateUi(self, multiVimWidget):
        multiVimWidget.setWindowTitle(QtGui.QApplication.translate("multiVimWidget", "MultiVim", None, QtGui.QApplication.UnicodeUTF8))
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.tab), QtGui.QApplication.translate("multiVimWidget", "Tab 1", None, QtGui.QApplication.UnicodeUTF8))
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.tab_2), QtGui.QApplication.translate("multiVimWidget", "Tab 2", None, QtGui.QApplication.UnicodeUTF8))
        self.label_2.setText(QtGui.QApplication.translate("multiVimWidget", "Python :", None, QtGui.QApplication.UnicodeUTF8))
        self.evaluateButton.setText(QtGui.QApplication.translate("multiVimWidget", "Evaluate", None, QtGui.QApplication.UnicodeUTF8))

