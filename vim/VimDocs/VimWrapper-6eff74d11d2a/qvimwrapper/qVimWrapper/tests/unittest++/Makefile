CXX = g++
CXXFLAGS ?= -g -ansi -Wall -W -ansi # -pedantic
LDFLAGS ?= 
SED = sed
MV = mv
RM = rm

.SUFFIXES: .o .cpp

src = AssertException.cpp \
	Test.cpp \
	Checks.cpp \
	TestRunner.cpp \
	TestResults.cpp \
	TestReporter.cpp \
	TestReporterStdout.cpp \
	ReportAssert.cpp \
	TestList.cpp \
	TimeConstraint.cpp \
	TestDetails.cpp \
	MemoryOutStream.cpp \
	DeferredTestReporter.cpp \
	DeferredTestResult.cpp \
	XmlTestReporter.cpp

  src += Win32/TimeHelpers.cpp

objects = $(patsubst %.cpp, %.o, $(src))

all: $(objects)

%.o : %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $(patsubst %.cpp, %.o, $<)

