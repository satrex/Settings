

project(test_qvimwrapper)

include_directories( ${CMAKE_SOURCE_DIR}/qvimwrapper )

########### next target ###############

set(testlib_SRC
    unittest++/AssertException.cpp 
	unittest++/Test.cpp 
	unittest++/Checks.cpp 
	unittest++/TestRunner.cpp 
	unittest++/TestResults.cpp 
	unittest++/TestReporter.cpp 
	unittest++/TestReporterStdout.cpp 
	unittest++/ReportAssert.cpp 
	unittest++/TestList.cpp 
	unittest++/TimeConstraint.cpp 
	unittest++/TestDetails.cpp 
	unittest++/MemoryOutStream.cpp 
	unittest++/DeferredTestReporter.cpp 
	unittest++/DeferredTestResult.cpp 
	unittest++/XmlTestReporter.cpp
    unittest++/Win32/TimeHelpers.cpp
)

set(test_qvimwrapper_SRC
    ../qvimwrapper/plog.cpp

    main.cpp
)


add_executable(test_qvimwrapper ${test_qvimwrapper_SRC} ${testlib_SRC} )


