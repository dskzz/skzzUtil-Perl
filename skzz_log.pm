# Generic wrapper for perl log
# 
# 6-5-12
#
#!/usr/bin/perl 

##		LEVELS OF ERROR.  Generally for run-time builds, we will want to use 2 or 3.  So variations between 4 and 5 are fairly moot. 
#		0 - lowest level, this is for run time debugging.  Like Dumping a trouble variable
#		1 - Information that should be printed but not for debugging - for example, printed updates 
#		2 -  Information that must be printed except in the least verbose manner of running.  Sectional updates, 
#		3 - Errors that are non-fatal, like a timeout.  Can also use this for #2 but even more vital information.   Basically, if it is here it will be printed or logged. 
#		4 - Fatal errors that will kill the point of the program...passing a bad url, mysql failure and indicate something is totally wrong.
#		5 - Print at all costs!!  Ususally, fatal errors that can potentially destroy the program or mess up the logic

BEGIN{push @INC, '/home/palsmysql/util/'};
use strict;

package skzz_log;
use Data::Dumper;
#use Log::Simplest;
use DateTime;

#my $DT = DateTime->new;

my $DEBUG_LEVEL = 0;
my $LOG_LEVEL = 0;

my $LOG_LOC = './';


sub new
{
    my $class = shift;
	my $log_location = shift;		#full path and filename.

#	${LOG_DIR} = $log_location;		#for log::Simplest
    
	my $self = {
		log_location=>$log_location,
		log_level=> 0,
		debug_level=> 0,
		file_handle=>undef
    };
	

	# DATA SOURCE NAME	
    bless $self, $class;
	$self->create_log() unless $log_location;	#if no log location given then don't create a log.
	
    return $self;
}

sub debug_level
{
	my $self = shift;
	my $level = shift;
	
	$self->{debug_level} = $level if $level;
	return $self->{debug_level};
}


sub log_level
{
	my $self = shift;
	my $level = shift;
	
	$self->{log_level} = $level if $level;
	return $self->{log_level};
}


sub log_location
{
	my $self = shift;
	my $log_location = shift;
	
	#if log fh exists, close, reinitialize.
	
	$self->{log_location} = $log_location if $log_location;
	return $self->{log_location};
}

sub create_log
{
	my $self = shift;	
	my $loc = $self->{log_location};
	
	$self->o("NO LOG LOCATIONS SET", 5) unless $loc;
	
	open( $self->{file_handle}, ">>", "$loc" );
	
	print {$self->{file_handle}} &timestamp." - LOG STARTED";
}

sub close 
{
	my $self = shift;
	close {$self->{file_handle}};
}

sub o
{
	my $self = shift;
	my $text = shift;
	my $level = shift;
	
	$level = 0 unless $level;
	
	print "$text\n" if $level >= $DEBUG_LEVEL;
}

sub timestamp
{
	my $dt = DateTime->now();
	 $dt->set_time_zone( 'America/New_York' );
	 
	my $day = $dt->ymd;
	my $time = $dt->hms;
	
	my $log_time = $day." ".$time;
	return $log_time;
}

sub log
{
	my $self = shift;
	my $text = shift;
	my $level = shift;
	
	$level = 0 unless $level;
	
	$self->o("NO FILE HANDLE", 5) unless $self->{file_handle};
	print {$self->{file_handle}} timestamp()." - $text\n" if $level >= $LOG_LEVEL;
	 #use Log::Simplest;
	#&Log("Informative log message");
	#&Fatal("I am dying...");
}

sub olog
{
	my $self = shift;
	my $text = shift;
	my $level = shift;
		
	$self->o($text, $level);
	$self->log($text, $level);
}


return 1;
