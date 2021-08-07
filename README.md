Wrappers are obvious.
util file has all sorts of useful stuff I've used over eyars. 
Log is an extensive logging system with variable verbosity, easy dumping to file, handles both single line and big dumps.

Web wrapper wraps WWW::Mechanize, uses same function  names.  Except that get wraps to _get - _get basically is the vanilla.  get( ) recurses on timeout and changes UA
