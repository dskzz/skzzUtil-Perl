#!/usr/bin/perl

use strict;

BEGIN{push @INC, '/home/pals/spiders/new_spiders'};	


# Generic wrapper for perl DBI mysql
# Usage: skzz_mysql_wrapper->new(  $database_name, $host, $port, $user, $pass )
# 6-5-12
#
#!/usr/bin/perl 

BEGIN{push @INC, '/home/palsmysql/util/'};
use strict;

package skzz_web_wrapper;
use Data::Dumper;
use WWW::Mechanize;
use Data::Validate::URI qw(is_uri);
use skzz_util;
use skzz_log;
use DateTime;

use config;



#my $mech = undef;
my $log = skzz_log->new( 'c:\\tmp\\skzz_web.log');

my $default_useragent = #'useragent=>Googlebot/2.1 ( http://www.googlebot.com/bot.html),';
				'useragent=>Mozilla/5.0 (compatible; Konqueror/3.3; Linux 2.6.8-gentoo-r3; X11';
my $default_timeout = 'timeout=>4'; #seconds

my @retry_codes = qw/408 409 502 503 504/;
my $RETRIES = 2;

my $test_site = 'http://www.google.com';

my $CODE_ERROR_404 = -3;
my $CODE_INVALID_URL = -2;
my $CODE_ERROR_GET = -1;
my $CODE_ERROR_RETRY = 1;
my $CODE_OK = 0;

my $URL =undef;
 
sub new
{
    my $class = shift;
	#my $mech_param = shift;

	#my $p = $mech_param;
	
	my %p = ('autocheck'=>'0','stack_depth'=>'100','agent'=>'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1');  # unless $p;
	
    my $self = {
			_url=>' ',
			code=>undef,
			mech=>undef
    };
	
	# DATA SOURCE NAME	
	
	
	$log->o("Created Mech with parameters\n".Dumper(\%p));
	print "mech created...\n";
    bless $self, $class;
	$self->{'mech'} = WWW::Mechanize->new( %p  );	#mech parameters
   	return $self;
}




sub test 
{
	#test uses 	1 line php script in root of localhost: <?php var_dump ( $_SERVER ); ?>  
	#pass with a parameter and it wont dump the server information
	$log->o("Testing");
	my $self = shift;
	my $supress = shift;
	$self->{'mech'}->get('http://127.0.0.1/sig.php');
	my $c = $self->{'mech'}->content;
	#$c =~ 
	$c =~ s/<.*?>//g;
	$c =~ s/=&gt;/=>/g;
	 
	$log->o( "Test Data Supressed\n" ) if ($supress);
	print $c unless $supress;
	
	$self->process_response();
}

sub set_url
{
	my $self = shift;
	my $url = shift;
	
	$self->{_url} = $url if $url ;
}

sub get_unprotected
{
	my $self = shift;
	my $url = shift;
	return unless $url;
	
	$self->{'mech'}->get( $url );
	wait until $self->{'mech'}->success;
}

sub uri
{
	my $self = shift;
	my $link = $self->{'mech'}->uri();
	return $link;

}


sub res
{
	my $self = shift;
	my $res = $self->{'mech'}->res();
	return $res;

}

sub _get		#internal get mechanize, only gets and waits
{
	my $self = shift;
	my $url = shift;
	my $attempt = shift;
	
	my $t = time() * 1000 + 400;
	my $time = DateTime->from_epoch(epoch => $t/1000)->format_cldr('h:m:s.S');	
	$attempt++;
	
	$URL = $url unless !$url;
#	$log->o("At $time getting ".$URL, 1);	
	
	$self->{'mech'}->get( $URL );
	my $i = 0;

	#timeout
	until ( $self->{'mech'}->success || ( (( time() * 1000 + 400) - $t  ) >20000 ) ) { }
	

	#recurse on fail
	my $r = $self->get_response_code();
	return -1 if ( $attempt >15  && $r eq 500 );
	if ( $r eq 500 )
	{
		my $wait_len = 2 * int($attempt / 5) ;
		warn "TIMEOUT Try $attempt - Waiting " . $wait_len ." secs. \n";
		sleep $wait_len ; #; * int( $attempt / 2 );
		$self->change_agent( );
		$self->_get($url , $attempt);
	}
	elsif ( $r =~ /^4\d\d/ )
	{
		warn "Failed $r on $attempt tries; $url\n";
	}
	else
	{
		return $r;
	}
	
	
	
}

#returns 0 if cool
#returns -1 if problem.
#Use get_response_code( ) to find out the  code 
sub get
{
	my $self = shift;
	my $url = shift;
	$url = "http://$url" if $url !~ /^http:\/\//;

	
	unless ( is_uri( $url ) )
	{
		$log->o( "Invalid uri: $url", 4 );	
		return $CODE_INVALID_URL;
	}
	
	my $response = $self->_get( $url );
		
	$self->change_agent( ) if $response eq $CODE_ERROR_RETRY;		#retry if there is an error
	#$response = $self->retry if $response eq $CODE_ERROR_RETRY;		#retry if there is an error
	
	return $self->process_final_response ($response);
	#at this point will have a 1 if retries times elapsed, will have a -1 if we have connectivity issues, will have a 0 is successful.
	
	
}

sub get_response_code
{
	my $self = shift;
	my $response = $self->{'mech'}->response();
	return $response->code;
	
}

sub change_agent
{
	my $self = shift;
	#random dance for new alias should be in other function
	my @alias = $self->{'mech'}->known_agent_aliases();
	my $i = skzz_util::random($#alias);
	my $new = $alias[$i];
	print "New agent - $new\n";
	$self->{'mech'}->agent_alias( $new );
}


sub process_response
{
	my $self = shift;
	my $resp = shift; 	#from get
	
	#return $CODE_ERROR_RETRY unless $resp;		#self calculated timeout at 25 seconds + 
	
	my $response = $self->{'mech'}->response();
	my $code = $response->code;

	$self->{code} = $code;
	$log->o("Response: $code") if $code ne 200;
	
	return $CODE_ERROR_404 if $code=~ /40\d/;
	return undef if $response->is_success ;

	$log->o("Problem in get operation: $code",1);
	return $CODE_ERROR_RETRY if (grep {$_ eq $code} @retry_codes);	#return wiht a 1 if we hit a retry code.
	
	
	return $self->problem if $code =~ /3\d\d/;	
	return $self->problem if $code =~ /4\d\d/;
	return $self->problem if $code =~ /5\d\d/;
}
		
	
sub retry
{
	my $self=shift;
	my $base = 2; #seconds to the ^ of retry number
	
	my $response = 1;
	my $try = 0;
	$log->o("Problems connecting. Timeout.",2);
	while ( $response == 1 )
	{
		$try++;
		my $wait = 5* ( $base **$try );
		last if $try >= $RETRIES;		
		$log->o("Retrying. Attempt $try of $RETRIES. Waiting $wait seconds",1);
		sleep( $wait );
		
		$response = process_response ( $self->_get () );
				
		#if kicks out OK then we are good. 
		#if kicks out problem then it is handled via returns
		#if still on -1 (retry) then check times, quit if exceed max attempts, then sleep, then do again.If exceeded, return 1 (retry) status code.
	}
	
	$log->log("Finished attempting to complete after $try attempts. Mech code is: $response. HTTP Status line is ".$self->{'mech'}->response->status_line,4) if $try >1;	#give i one chance to try again without error
	return $response;
}
	
sub problem
{
	my $self = shift;
#	$self->olog( $self->{'mech'}->response->status_line, 4 );
	return $CODE_ERROR_GET;
}
	

sub process_final_response 
{
	my $self = shift;
	my $response = shift;
	
#	$log->o("Final result of get: $response.", 2) if $response ;
#	$log->o("GET Succeded", 2) if !$response ;

	return $response;
	#from here we may want to pass a message about the results to a central controller.  Or this could also be handled by the calling program.

}

sub get_link_text
{
	my $self = shift;
	my $href = shift;
	
	my $link = $self->{'mech'}->find_link( url => $href );
	
	#print Dumper($link);
	return $link->text() if $link;
	#url => 'string', and url_regex => qr/regex/,
	
	
}

sub content
{
	my $self = shift;
	return $self->get_content;
}

sub get_content
{
	my $self = shift;
	my $c = $self->{'mech'}->content;
	$c =~ s/&quot;/"/g;
	return $c;
}

sub get_links_in_content
{
	my $self = shift;
	my $c = shift;
	
	$c = $self->{'mech'}->content() unless $c;
	my @links = $c =~ m{<a href=(.*?)>}sig;
	$_ =~ s/['"]//gs foreach @links;
	return @links;
}

#CRITERIA MAY BE:
#	NEEDS TO BE HASH ref passed to this.  Will return -1 unless is hash.  
#	KEYS: text, url, url_abs, id, class, tag, name  and each may be _text or _regex seperated by comma
#	Example: 
#	my %find = (url_regex=>qr/vote/i);
#	my @c = $web->find_all_links( \%find );
sub find_all_links
{
	my $self = shift;
	my $hashRef_criteria = shift;
	return -1 unless $hashRef_criteria =~ /hash/i;
	my %criteria_hash = %{ $hashRef_criteria };
	
	my @link_list = $self->{'mech'}->find_all_links( %criteria_hash );
	return @link_list;
}


sub find_in_content
{
	my $self = shift;
	my $search = shift;
	/()/;
	$self->{'mech'}->content =~ m{$search};
	
	return $1;
}

sub field
{
	my $self = shift;
	my $field_name = shift;
	my $value = shift;
	
	$self->{'mech'}->field( $field_name, $value );
}

#forms start at 1 not 0
sub form_number
{
	my $self = shift;
	my $num = shift;

	$self->set_form( $num );
}

sub set_form
{
	my $self = shift;
	my $num = shift;
	$self->{'mech'}->form_number($num);
	wait until $self->{'mech'}->success;
}

sub form_name
{
	my $self = shift;
	my $name = shift;
	$self->set_form_name( $name );
}

sub set_form_name
{
	
	my $self = shift;
	my $name = shift;
	wait until $self->{'mech'}->success;
	my $x = $self->{'mech'}->form_name($name);
	
	wait until $self->{'mech'}->success;
}
	
sub select
{
	my $self = shift;
	my $field_name = shift;
	wait until $self->{'mech'}->success;
	my $value = shift;
	#$mech->form_with_fields( ( $field_name ) );

	$log->o("Select - $field_name, $value");
	$self->{'mech'}->select( $field_name, $value );
}

sub submit
{
	my $self = shift;
	$self->{'mech'}->submit(  );
	wait until $self->{'mech'}->success;
}


sub doPostBack
{
    my $self = shift;
	my $target = shift;    ## first argument in the __doPostBack() call in javascript
    my $arg    = shift;    ## second argument in the __doPostBack() ca+ll in javascript
	my $form = shift;
	my $no_submit = shift;

	$form = 'aspnetForm' unless $form;
	
	my $agent  = $self->{'mech'};    ## WWW::Mechanize agent-object passed in
    
#	print "$target\n$arg\n";<STDIN>;
    # convert the passed in string
    $target =~ s/\$/:/g;

    $agent->form_id( "$form" );
    $agent->field('__EVENTTARGET', $target);
    $agent->field('__EVENTARGUMENT', $arg);

	
	
	if ( !$no_submit )
	{
		
		$agent->submit();
		wait until $agent->success;
	}
	else
	{
		print "NO SUBMIT\n";
	}
} #endsub doPostBack

sub post
{
	my $self = shift;
	my $url = shift;
	my %post = shift;

	$self->{'mech'}->post( $url, %post );
}

sub get_mech
{
	my $self = shift;
	return $self->{'mech'};
}

return 1;
