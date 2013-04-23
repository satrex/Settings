
import py, sys, re
sys.path.append( '..' )
sys.path.append( '.' )

from ..netbeanArgs import parseNetbeanArgs, simplifyBackslash, packArgs, backslashEscape

class TestNetbeanArgs:

    def testParseReplyArgsNumber( self ):
        assert (123,) == parseNetbeanArgs( '123', 'NUM' )
        assert (123,-123) == parseNetbeanArgs( '123 -123', 'NUM NUM' )

    def testRuNumber( self ):
        assert re.match( '(-?\d+)', '123')
        assert re.match( '(-?\d+)', '-123')
        assert re.match( '(-?\d+)$', '-123 123') == None


    def testReString( self ):
        assert re.match( '"123"', '"123"' )
        assert re.match( r'"[^"]*"', r'"123"' )
        assert re.match( r'"((?:[^"])*)"', r'"123"' ).group(1) == r'123'
        assert re.match( r'"((?:[^"]|")*)"', r'"12"3"' ).group(1) == r'12"3'
        assert re.match( r'"((?:[^"]|(?:\"))*)"', r'"12\"3"' ).group(1) == r'12\"3'
        assert re.match( r'"((?:[^\\]|(?:\\["]))*)"', r'"12\"3"' ).group(1) == r'12\"3'
        assert re.match( r'"((?:[^\\]|\\["ntr\\])*)"', r'"12\"3"' ).group(1) == r'12\"3'
        assert re.match( r'"((?:[^\\]|\\["ntr\\])*)"', r'"12\"\\\n3"' ).group(1) == r'12\"\\\n3'

    def testParseReplyArgsString( self ):
        sString1 = '"123"'
        sString2 = r'"1\"2\t3\r\\4\n5"'
        sString3 = r'"\\ \" "' # if you can survive this, you're good !

        assert ('123',) == parseNetbeanArgs( sString1, 'STR' )

        assert ( '1"2\t3\r\\4\n5', ) == parseNetbeanArgs( sString2, 'STR' )

        assert ( '\\ " ',) == parseNetbeanArgs( sString3, 'STR' )

        expected = ( '123', '1"2\t3\r\\4\n5', '\\ " ' )
        result = parseNetbeanArgs( '%s %s %s' % (sString1, sString2, sString3) , 'STR STR STR' )
        assert expected == result

    def testParseReplyArgsPos( self ):
        assert ((12,34),) == parseNetbeanArgs( '12/34' , 'POS' )
        assert ((12,34),(45,67)) == parseNetbeanArgs( '12/34 45/67' , 'POS POS' )

    def testParseReplyArgsBool( self ):
        assert (True,False) == parseNetbeanArgs( 'T F', 'BOOL BOOL' )

    def testParseReplyArgsOptNum( self ):
        assert (None, 123, -456) == parseNetbeanArgs( 'none 123 -456', 'OPTNUM OPTNUM OPTNUM' )

    def testParseReplyArgsPath( self ):
        sPath1 = r'"c:\\windows"'
        sPath2 = '"/usr/bin"'
        assert ( simplifyBackslash(sPath1[1:-1]), sPath2[1:-1] ) == parseNetbeanArgs( sPath1 + ' ' + sPath2, 'PATH PATH' )

    def testParseReplyArgsOptMsg( self ):
        s1 = ''
        s2 = 'this is a message'
        assert (None,) == parseNetbeanArgs( s1, 'OPTMSG' )
        assert (s2,) == parseNetbeanArgs( s2, 'OPTMSG' )

    def testParseReplyArgsWithError( self ):
        s = r'123 "1\"2 3" 12/34 T F none 123 "c:\\windows" "/usr/bin"'

        py.test.raises( ValueError, parseNetbeanArgs, '123', 'BLABLABLA' )

        assert (123, r'1"2 3', (12,34), True, False, None, 123, r'c:\windows', '/usr/bin' ) == \
            parseNetbeanArgs( s, 'NUM STR POS BOOL BOOL OPTNUM OPTNUM PATH PATH' )

        for expr in [ 'STR', 'POS', 'BOOL', 'PATH' ]:
            py.test.raises( ValueError, parseNetbeanArgs, s, 
                    '%s STR POS BOOL BOOL OPTNUM OPTNUM PATH PATH' % expr )

        for expr in [ 'NUM', 'POS', 'OPTNUM', 'BOOL' ]:
            py.test.raises( ValueError, parseNetbeanArgs, s, 
                    'NUM %s POS BOOL BOOL OPTNUM OPTNUM PATH PATH' % expr )

        for expr in [ 'NUM', 'STR', 'BOOL', 'OPTNUM', 'PATH' ]:
            py.test.raises( ValueError, parseNetbeanArgs, s, 
                    'NUM STR %s BOOL BOOL OPTNUM OPTNUM PATH PATH' % expr )

        for expr in [ 'NUM', 'STR', 'POS', 'OPTNUM', 'PATH' ]:
            py.test.raises( ValueError, parseNetbeanArgs, s, 
                    'NUM STR POS %s BOOL OPTNUM OPTNUM PATH PATH' % expr )

        for expr in [ 'NUM', 'STR', 'POS', 'BOOL', 'PATH' ]:
            py.test.raises( ValueError, parseNetbeanArgs, s, 
                    'NUM STR POS BOOL BOOL %s OPTNUM PATH PATH' % expr )

        for expr in [ 'STR', 'POS', 'BOOL', 'PATH' ]:
            py.test.raises( ValueError, parseNetbeanArgs, s, 
                    'NUM STR POS BOOL BOOL OPTNUM %s PATH PATH' % expr )

        for expr in [ 'NUM', 'POS', 'BOOL', 'OPTNUM' ]:
            py.test.raises( ValueError, parseNetbeanArgs, s, 
                    'NUM STR POS BOOL BOOL OPTNUM OPTNUM %s PATH' % expr )

        py.test.raises( ValueError, parseNetbeanArgs, '123 456', 'NUM' )
        py.test.raises( ValueError, parseNetbeanArgs, '123', 'NUM NUM' )

    def testSimplifyBackslash( self ):
        s = r'\\ \n \" \t \r'
        assert simplifyBackslash( s ) == '\\ \n " \t \r'

        # tricky case
        s = r'\\test\\notest\\read\\"'
        assert simplifyBackslash( s ) == '\\test\\notest\\read\\"'

    def testBackslashEscape( self ):
        src = '\\ \n " \t \r'
        ret = r'\\ \n \" \t \r'
        assert backslashEscape( src ) == ret

        # tricky case
        s = r'\test\notest\read\"'
        assert backslashEscape( s ) == r'\\test\\notest\\read\\\"'


    def testPackArgs( self ):
        assert packArgs() == ''
        assert packArgs( 'coucou', 123, -45, (1,2), True, False ) == ' "coucou" 123 -45 1/2 T F'
        assert packArgs( '< \\ \n \t \r " >' ) == r' "< \\ \n \t \r \" >"'
        
