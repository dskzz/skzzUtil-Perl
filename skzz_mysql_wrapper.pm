# Generic wrapper for perl DBI mysql
# Usage: skzz_mysql_wrapper->new(  $database_name, $host, $port, $user, $pass )
#
#!/usr/bin/perl 

BEGIN{push @INC, '/home/palsmysql/util/'};
use strict;

package skzz_mysql_wrapper;
use Data::Dumper;

use skzz_util;

# PERL MODULES WE WILL BE USING
use DBI;
use DBD::mysql;
use DateTime::Format::MySQL;
use Date::Manip;
 
# CONFIG VARIABLES
my $platform = "mysql";

my $dsn;

my $NORMAL_LOG = './pals-db-log'; 
my $ERROR_LOG = './pals-db-err';

my $DEBUG_LEVEL = 5;
sub o
{
	my $text = shift;
	my $level = shift ||  0 ;
	
	print "*** $text\n" if ($level >= $DEBUG_LEVEL);
}

sub new
{
    my $class = shift;
	my $database = shift;
	my $host = shift;
	my $port = shift;
	my $user = shift;
	my $pass = shift;
	
	$host = 'localhost' unless $host;
	$port = '3306' unless $port;
	$user = 'root' unless $user;
	$pass = '' unless $pass;
	die "NEED DATABASE!!!" unless $database;
	 
	$dsn = "dbi:mysql:$database:$host:$port";

    my $self = {
        DBI_connect =>'',
		DBI_query_handle =>'',
		debug =>'',
		die_on_error=>'0',
		last_query=>'',
		sql_state=>''
    };

	o("DSN: $dsn\n",3);
	# DATA SOURCE NAME	
	
    bless $self, $class;
	$self->{'DBI_connect'} = DBI->connect($dsn, $user, $pass);	
    return $self;
}

sub initialize
{
	my $self = shift;
	# PERL DBI CONNECT
#	$self->{DBI_connect} = DBI->connect($dsn, $user, $pw);	
}

sub die_on_error
{
	my $self = shift;
	my $val = shift;
	if ($val == 1)
		{$self->{'die_on_error'} = 1 ;}
	else
		{$self->{'die_on_error'} = 0 ;}
}

sub debug_mode
{
	my $self = shift;
	
	$self->{debug} = 1;

}

sub get_timestamp
{
	return skzz_util::get_timestamp();
}

sub log
{
	my $self = shift;
	my $type = shift;
	my $text = shift;
	my $error = shift;	#optional
		
	my $time_str = skzz_util::get_timestamp();
	
	if (!$error)
	{
		open LOG, ">>$NORMAL_LOG";
		print LOG $time_str." - ". $type." - ". $text. "\n";
		close LOG;
	
	}
	if ($error)
	{
		open LOG, ">>$ERROR_LOG";
		print LOG $time_str." - ERR -". $type." - ". $text. "\n";
		close LOG;
	}
	
}

sub dump
{
	my $self = shift;
	print Dumper(  \%{$self });
}

###############################################################################################
##
##	END ADMINISTRATIVE FUNCTIONS
##
##	BEGIN SQL FUNCTIONS
##
################################################################################################
sub select_get_hashref
{
	my $self = shift;
	my $query = shift;
	
#	print "[-] select_get_hashref\n";
#	print "[-] Current: $query\n";
#	print "[-] Last: $self->{'last_query'}\n";
	

	if( $query && ( $query ne $self->{'last_query'} ) )
	{

		$self->sql_write( $query );
	}

	
	my $h_ref = $self->{DBI_query_handle}->fetchrow_hashref( );
#	print Dumper( $h_ref );
#	<STDIN>;
	return $h_ref;
}


sub get_num_rows
{
	my $self = shift;
	return $self->{ 'DBI_query_handle' }->rows;
}

sub get_single_val_from_sqlwhere
{
	my $self = shift;
	my $val = shift;
	my $table = shift;
	my $where = shift; 

	return unless $val;
	return unless $table;
	
	$where = " WHERE $where " if $where;  #add the where code, this lets you use it without a where statement.
	
	my $q = "SELECT $val from $table $where";
	
	return $self->get_single_value( $q );
}



sub get_last_ID
{
	my $self = shift;
	return $self->{DBI_query_handle}->{'mysql_insertid'}
}

sub get_1_row_results_as_array
{
	my $self = shift;
	my $sql = shift;
	
	my $q = $self->sql_write( $sql );
	
	my $a_ref = $q->fetchrow_arrayref( );
	
	my @a = @{ $a_ref };
	return @a;
}


sub get_1_row_results_as_hash
{
	my $self = shift;
	my $sql = shift;
	
	my $q = $self->sql_write( $sql );
	
	my $h_ref = $q->fetchrow_hashref( );
	
	my %h = %{ $h_ref };
	return %h;
}



sub get_row_as_hash
{
	my $self = shift;
	my $handle = shift;
#	my $query_handle = $self->{DBI_connect};
	
	return unless $handle;
	my $a_ref = $handle->fetchrow_hashref(  ) or return; 
	
	return unless $a_ref;
	my %h = %{ $a_ref } ;
	return %h;
}


sub get_single_value 
{
	my $self = shift;
	my $sql = shift;
	
	my $q = $self->sql_write( $sql );

	my $a_ref = $q->fetchrow_arrayref( );
	return "" if( !$a_ref );

	my @a = @{ $a_ref };
	return shift @a;
}


sub insert_and_get_ID
{
	my $self = shift;
	my $sql = shift;

	my $q = $self->sql_write( $sql  );

	return $self->get_last_ID(  );
}


sub get_single_col 
{
	my $self = shift;
	my $query = shift or return;
	
	my $query_handle = $self->{DBI_connect}->prepare($query);
	my $return = $query_handle->execute();
	
	o( $return,3) if $self->{'debug'};
	
	o( "\nResult:$return\nq:\n$query\n",3) if $return ne 1 && $self->{'debug'};
	my $ref = $self->{DBI_connect}->selectcol_arrayref($query);
	my @ret_array;
	
	while ( my $item = $query_handle->fetchrow_arrayref() )
	{
		my @a = @{ $item };
		
		push @ret_array, $a[0];
	}
	
	return @ret_array;
}

sub write_and_get_row_hash
{
	my $self=shift;
	my $query = shift;
	
	my $h = $self->sql_write ( $query);
	return $self->get_row_as_hash( $h );

}

sub get_state
{
	my $self = shift;
	return $self->{sql_state};
	
}

sub err
{
	return $DBI::errstr;
}

sub sql_write
{
	my $self=shift;
	my $query = shift;
	$self->{'last_query'} = $query;

	my $query_handle = $self->{DBI_connect}->prepare($query);

	# EXECUTE THE QUERY
	my $return = $query_handle->execute();
#	print $query;
	o("SQL  Result: $return \nErrstr: $DBI::errstr\n Q: \n$query\n",3) if $self->{debug}; 
	o( "SQL Error Result:$return.\nErrstr:".$DBI::errstr."\nQ:\n$query\n",3) unless $return >=1;
	die "DIED because skzz_mysql_wrapper set to die on execute error.\n".$DBI::errstr."\n" if ( $self->{'die_on_error'} && $DBI::errstr);
	$self->{DBI_query_handle} = $query_handle;
	$self->{sql_state} = $self->{DBI_query_handle}->state;
	
	return $query_handle;
}

sub get_results_hash_ref
{
	my $self = shift;
	
	return $self->{DBI_query_handle}->fetchrow_hashref();
}


sub reset_count
{
	my $self=shift;
	my $table = shift;

	my $sql = "ALTER TABLE $table AUTO_INCREMENT = 1;";
	$self->sql_write( $sql );
}



sub bank_generic_hash
{
	my $self = shift;
	my $table =shift;
	my $href = shift;
	
	my %bank_hash = %{$href};
	
	my @cols; my @vals;
	
	foreach my $key ( keys %bank_hash )
	{
		next unless $bank_hash{$key};
		my $val = $bank_hash{$key};
		$val =~ s/'//g;
		$val =~ s/""/"/g;
		
		if ( $key =~ /date/ && $val =~ /\d\d/)
		{
#			print "Found date $val\n";
			$val = $self->conv_date( $val );
#			print "Converted to $val\n";
		}
		
		
		push @cols, $key;
		push @vals, "'$val'";
	}
	
	my $cols = join ",", @cols;
	my $vals = join ",", @vals;
	
	my $sql = "INSERT INTO $table ($cols) VALUES ($vals)";

	$self->sql_write($sql);
}

sub retrieve_generic_hash
{
	my $self = shift;
	my $table =shift;
	my $href = shift;
	
	my %bank_hash = %{$href};
	
	my @cols; my @vals;
	
	foreach my $key ( keys %bank_hash )
	{
		next unless $bank_hash{$key} && $bank_hash{$key} ne '0' && $bank_hash{$key} ne 0;
		my $val = $bank_hash{$key};
		$val =~ s/'//g;
		$val =~ s/""/"/g;
		
		if ( $key =~ /date/ && $val =~ /\d\d/)
		{
#			print "Found date $val\n";
			$val = $self->conv_date( $val );
#			print "Converted to $val\n";
		}
		
		
		push @cols, $key."\n";
		push @vals, "'$val'\n";
	}
	
	my $cols = join ",", @cols;
	my $vals = join ",", @vals;
	
	my $sql = "INSERT INTO $table \n($cols) \nVALUES \n($vals)";
	return $sql;
}


sub retrieve_generic_hash_INSERT_UPDATE
{
	my $self = shift;
	my $table =shift;
	my $href = shift;
	
	my %bank_hash = %{$href};
	
	my @cols; my @vals; my @params;
	
	foreach my $key ( keys %bank_hash )
	{
		next if $bank_hash{$key} eq "";
		next if !defined $bank_hash{$key};

		next if $key =~ /^_/;

		my $val = $bank_hash{$key};
		$val =~ s/'//g;
		$val =~ s/""/"/g;
		
		if ( $key =~ /date/ && $val =~ /\d\d/)
		{
#			print "Found date $val\n";
			if( $val ne "0000-00-00" ){
				$val = $self->conv_date( $val );
			}
#			print "Converted to $val\n";
		}
		
		
		push @cols, $key."\n";
		push @vals, "'$val'\n";
		push @params, " $key = '$val' ";
	}
	
	my $cols = join ",", @cols;
	my $vals = join ",", @vals;
	my $params = join ",", @params;

	
	my $sql = "INSERT INTO $table \n($cols) \nVALUES \n($vals) ON DUPLICATE KEY UPDATE \n $params \n";

	return $sql;
}


sub retrieve_generic_hash_INSERT
{
	my $self = shift;
	my $table =shift;
	my $href = shift;
	
	my %bank_hash = %{$href};
	
	my @cols; my @vals;
	
	foreach my $key ( keys %bank_hash )
	{
		next if $bank_hash{$key} eq "";
		next if !defined $bank_hash{$key};

		next if $key =~ /^_/;

		my $val = $bank_hash{$key};
		$val =~ s/'//g;
		$val =~ s/""/"/g;
		
		if ( $key =~ /date/ && $val =~ /\d\d/)
		{
#			print "Found date $val\n";
			$val = $self->conv_date( $val );
#			print "Converted to $val\n";
		}
		
		
		push @cols, $key."\n";
		push @vals, "'$val'\n";
	}
	
	my $cols = join ",", @cols;
	my $vals = join ",", @vals;
	
	my $sql = "INSERT INTO $table \n($cols) \nVALUES \n($vals)";
	return $sql;
}

sub close
{
	my $self=shift;
	$self->{DBI_connect}->finish;
}	



###############################################################################################
##
##	END SQL FUNCTIONS
##
##	BEGIN HELPER FUNCTIONS
##
################################################################################################
sub conv_date
{
	my $self=shift;
	my $date_to_conv = shift;
#	print $date_to_conv;
	my $date = ParseDate($date_to_conv);
	/()()()/;
	$date =~ /(\d\d\d\d)(\d\d)(\d\d)/;
	$date = "$1-$2-$3";
	return $date;
#	yyyy-mm-dd
}
#takes xx/xx/xxxx
sub convert_date
{
	my $self=shift;
	my $date = shift;
	return unless $date;

	/()()()/;
	$date =~ /(\d*)\/(\d*)\/(\d.*)/;
	my $month = $1;
	my $day = $2;
	my $year = $3;
	
	my $newdate = "$year-$month-$day";
#	my $dt = DateTime::Format::MySQL->parse_date( $newdate );

#	my $dt = DateTime::Format::MySQL->format_date( $newdate );
	return $newdate;
}


return 1;
