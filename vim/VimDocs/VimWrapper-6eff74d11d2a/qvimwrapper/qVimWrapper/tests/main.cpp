
#include "plog.h"
#include "unittest++/UnitTest++.h"

#define dbg PLogArea( "main", __FUNCTION__ ).dbg

TEST( SomeFailure )
{
    CHECK( false );        
}

class SomeFixture
{
public:
    SomeFixture() {
        dbg( "SetUp" );
    }        

    ~SomeFixture() {
        dbg( "TearDown" );
    }        

};


SUITE( SomeSuite )
{
    TEST_FIXTURE( SomeFixture, OneSuiteTest ) {
        dbg( "OneSuiteTest" );
        CHECK( false );        
    }        

    TEST_FIXTURE( SomeFixture, TwoSuiteTest ) {
        dbg( "TwoSuiteTest" );
        CHECK( false );        
    }        
}

int main( int argc, char ** argv )
{
    dbg( "Hello world!" );

    return UnitTest::RunAllTests();
}

