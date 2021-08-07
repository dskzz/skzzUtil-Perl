BEGIN{push @INC, '/home/pals/spiders/new_spiders'};	
BEGIN{push @INC, 'C:\Users\skz\Dropbox\prog\skzz_perl_library'};	
#Generic utilities 
# 6-5-12
#
#	get_timestamp - provides SQL friendly timestamp from localtime

use strict;

package skzz_util;
my $default_output_folder = 'D:\SkzTemp';
my $default_output_filename = 'output.html';


my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
my $CURRENT_YEAR = 12;


sub clean_newlines
{
	my $clean_string = shift;
	$clean_string =~ s/&nbsp;/ /g;
	$clean_string =~ s/[\n\l\f]{1,}/\n/g;
	$clean_string =~ s/\s{1,}/ /g;
	$clean_string =~ s/^\s{1,}//g;
	$clean_string =~ s/\s{1,}$//g;
	
	return $clean_string;
}


sub clean_all
{
	my $clean_string = shift;
	$clean_string =~ s/&nbsp;/ /g;
	$clean_string =~ s/<br>/ /g;
	$clean_string =~ s/<br \/>/ /g;
	$clean_string =~ s/<\/p>/ /g;
	$clean_string =~ s/<p>/ /g;
	$clean_string =~ s/[\n\l\f]{1,}/\n/g;
	$clean_string =~ s/\s{1,}/ /g;
	$clean_string =~ s/^\s{1,}//g;
	$clean_string =~ s/\s{1,}$//g;
	$clean_string =~ s/<.*?>/ /g;
	
	return $clean_string;
}

sub clean_all_tags
{
	my $s = shift;
	
	$s =~ s/<.*?>//g;

	return $s;
}

sub trim_hash
{
	return clean_hash( shift );
}

sub clean_hash
{
	my %h = %{ (shift) };
	
	foreach my $k (keys %h)
	{
		$h{$k} = regex_clean_trim( $h{$k} );
		$h{$k} =~ s/\n{1,}$//g;
		$h{$k} =~ s/^\n{1,}//g;
		$h{$k} =~ s/[^\x00-\x7f]//g;
		$h{$k} =~ s/^;//;
		
	}

	return %h;
}



sub clean_trim
{
	my $txt = shift;
	$txt =~ s/^\s{1,}//g;
	$txt =~ s/\s{1,}$//g;
	$txt =~ s/\s{1,}/ /g;
	return $txt;
}

sub timestamp
{
	return get_timestamp();
}




sub get_day_stamp
{
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my  $year = 1900 + $yearOffset;
	 $hour = $hour + 12 if $hour < 4;
 $hour = $hour - 4;
	$month++;

	$second = "0$second" if length($second) < 2;
	$minute = "0$minute" if length($minute) < 2;
	$minute = "0$hour" if length($hour) < 2;
	
	$month = "0$month" if length($month) < 2;
	$dayOfMonth = "0$dayOfMonth" if length($dayOfMonth) < 2;
	
#	my  $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
	my  $theTime = "$year-$month-$dayOfMonth";
	   return $theTime; 
}


sub get_timestamp
{
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my  $year = 1900 + $yearOffset;
	 $hour = $hour + 12 if $hour < 4;
 $hour = $hour - 4;
	$month++;

	$second = "0$second" if length($second) < 2;
	$minute = "0$minute" if length($minute) < 2;
	$minute = "0$hour" if length($hour) < 2;
	
	$month = "0$month" if length($month) < 2;
	$dayOfMonth = "0$dayOfMonth" if length($dayOfMonth) < 2;
	
#	my  $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
	my  $theTime = "$year-$month-$dayOfMonth $hour:$minute:$second";
	   return $theTime; 
}


sub convert_mdy_to_sql
{
	my ($month, $day, $year) = @_;

	return '0000-00-00' if ( !$month || !$day || !$year );
	
	$month = "0$month" if length($month) eq 1;
	$day = "0$day" if length($day) eq 1;
	if ( length($year) eq 2 )
	{
		$year = $year + 1900 if $year > 15;
		$year = $year + 2000 if $year < 15;
	}	

	return "$year-$month-$day";
}

sub convert_sql_to_mdy
{
	my $date = shift; 
	my $dont_truncate = shift;
	return $date if $date =~ /\d{1,2}[\/\\-]\d{1,2}[\/\\-]\d{2,4}/;
	my ($y, $m, $d) = $date =~ /(\d{4})-(\d{2})-(\d{2})/;
	
	$m =~ s/^0// unless $dont_truncate;
	$d =~ s/^0// unless $dont_truncate;
	$y =~ s/^..// unless $dont_truncate;
	
	return "$m/$d/$y";
	
}

sub split_date_and_time_for_sql
{
	my $x = shift;
	my ($date, $time) = $x =~ m{([\d-\/\\]{6,10}) ([\:\.AMP\d\s]{5,10})};
	
	$date = convert_date_to_sql( $date );
	$time = time_w_meridian_to_sql( $time );
	return "$date $time";
	#print "orig - $x & d - $date & t - $time\n";
}

sub convert_date_to_sql
{
	my $date = shift; 
	return $date if $date =~ /\d\d\d\d-\d\d-\d\d/;
	return date_to_sql( $date );
}


sub convert_date_to_short
{
	my $date = shift; 
	return $date unless $date =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
	
	my $year = $1;
	my $month = $2;
	my $day = $3;
	
	$year =~ /\d\d(\d\d)/;
	my $year_2 = $1;
	
	return remove_zero_from_date($month)."/".remove_zero_from_date($day)."/".$year_2;
}


sub date_to_sql
{
	my $date = shift; 
	return $date if $date =~ /\d\d\d\d-\d\d-\d\d/;
	return '0000-00-00' unless $date;
	my ($month, $day, $year);
	if ( $date =~ /\d\d\d\d-\d{1,2}-\d{1,2}/ )	{
		($year, $month, $day) = $date =~ m{(\d{2,4})-(\d{1,2})-(\d{1,2})} ;	
	}
	else	{
		($month, $day, $year) = $date =~ m{(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})} ;
	}
	
	$month = "0$month" if length($month) eq 1;
	$day = "0$day" if length($day) eq 1;
	if ( length($year) eq 2 )
	{
		$year = $year + 1900 if $year > 15;
		$year = $year + 2000 if $year < 15;
	}	

	return "$year-$month-$day";
	
}

sub parse_time_from_sql
{
	my $time = shift;
	my ($hour, $min, $sec);
	my $meridian;
	
	if ( $time =~ /(\d{1,2}):(\d{1,2}):(\d{1,2})/ )
	{
		$hour =$1; $min =$2; $sec = $3;
	}
	elsif ( $time =~ /(\d{1,2}):(\d{1,2})/ )
	{
		$hour =$1; $min =$2; $sec = 0;
	}
	
	if ( $hour >= 12  )
	{
		$hour = $hour - 12;
		$meridian = 'P.M.';
	}
	else
	{
		$hour = 12 if $hour eq 0;
		$meridian = 'A.M.';
	}
	
	$hour =~ s/^0//;
	
	my %ret;
	$ret{'hour'} = $hour;
	$ret{'minute'} = $min;
	$ret{'second'} = $sec;
	$ret{'meridian'} = $meridian;
	$ret{'print'} = "$hour:$min $meridian";
	
	return %ret;
}

sub parse_date
{
	my $date = shift;
	my %r;
	my ($month, $day, $year);
	if ( $date =~ /\d\d\d\d-\d{1,2}-\d{1,2}/ )	{
		($year, $month, $day) = $date =~ m{(\d{2,4})-(\d{1,2})-(\d{1,2})} ;	
	}
	else	{
		($month, $day, $year) = $date =~ m{(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})} ;
	}
	
	$r{'year'} = $year;
	$r{'month'} = $month;
	$r{'day'} = $day;
	return %r;
}

sub convert_letter_date_to_sql
{
	my $date = shift;
	my $year = shift;
	my %months = ('Jan'=>'01', 'Feb'=>'02', 'Mar'=>'03', 'Apr'=>'04', 'May'=>'05', 'Jun'=>'06', 'Jul'=>'07', 'Aug'=>'08', 'Sept'=>'09', 'Oct'=>'10', 'Nov'=>'11', 'Dec'=>'12', 
	'January'=>'01',	'February'=>'02',	'March'=>'03',	'April'=>'04',	'May'=>'05',	'June'=>'06',	'July'=>'07',	'August'=>'08',	'September'=>'09',	'October'=>'10',	'November'=>'11',
	'December'=>'12');
	/()()/;
	$date =~ m{(\w{3,})\s{1,}(\d{1,})} if $year;
	$date =~ m{(\w{3,})\s{1,}(\d{1,}),\s{0,1}(\d{2,4})} unless $year;
	my $month = $1;
	my $day = $2;
	$year = $3 unless $year;
	$day = "0$day" if length($day) eq 1;
	$month = "0$month" if length($month) eq 1;
	
	my $new_month = $months{$month} ;
	return "$year-$new_month-$day";
}

sub random
{
	my $low = shift;
	my $high = shift;
	
	if ( !$high )		#if no high given, then make single supplied value the high value.
	{
		$high = $low;
		$low = 0;
	}

	my $rmax = $high - $low;
	return int( rand( $rmax ) ) + $low;
}

sub time_w_meridian_to_sql
{
	my $time = shift;
	
	my ($hour, $minute) = $time =~ /(\d{1,2}):(\d{1,2})/;
	my $second = '00';
	
	if ( $time =~ /(\d{1,2}):(\d{1,2}):(\d{1,2})/ )
	{	$hour = $1; $minute = $2; $second = $3;
	}
	
	my $meridian = undef;
	if ( $time =~ /[pP]/ )
	{
		$meridian = 'P';
	}
	elsif ( $time =~ /[aA]/ )
	{
		$meridian = 'A';
	}
	
	if ( $meridian =~ /p/i && int($hour) < 12)
	{
		$hour = $hour + 12;
	}
	elsif ( $meridian =~ /a/i && $hour eq 12)
	{
		$hour = '00';
	}
	
	
	$hour = "0$hour" if length($hour) eq 1;
	
	return "$hour:$minute:$second";
	
}

sub process_time_to_sql
{
	my $h = shift;
	my $m = shift;
	my $am_pm = shift;
	my $sec = shift;
	
	$sec = '00' unless $sec;
	
	if ( $am_pm =~ /p/i )
	{
		if (!( $h eq 12 || $h eq 0 ) )
		{
			$h = $h + 12;
			$h = 0 if $h eq 24 ;
		}
	}	
		
	$h = '0'.$h if length($h) eq 1;
	$m = '0'.$m if length($m) eq 1;
	$sec = '0'.$sec if length($sec) eq 1;
	
	return "$h:$m:$sec";
}

#find_in_content_tag( \$content, <span class='find this'> [</span>]
sub find_in_content_tag
{
	my $content = ${ (shift) };	#gonna usually be big so pass ref
	my $tag = shift;
	my $param_closing = shift;
	
	/()/;
	$tag =~ /\<(.*?)\s/;
	
	my $closer = '</'.$1.'>';
	1 =~ /()/;
	
	#clobber if user supplied; optional.
	$closer = $param_closing if $param_closing;
	
	$content =~ m{$tag(.*?)$closer}s;
	my $result = $1;
	
	return $result;
}

sub parse_href
{
	my $link = shift;

	(my $new_link, my $text) = $link =~ m{<a.*?href=['"'](.*?)['"'].*?>(.*?)</a>}sgi;
	$text = regex_clean_trim( $text );
	$new_link = regex_clean_trim( $new_link );

	return ($new_link, $text);
}

sub regex_clean_trim
{
	my $txt = shift;
	$txt =~ s/^\s{1,}//g;
	$txt =~ s/\s{1,}$//g;
	$txt =~ s/\s{1,}/ /g;
	return $txt;
}

sub regex_extract_link
{
	my $txt = shift;
	
	/()/;
	$txt =~ m{href\s{0,}=\s{0,}['"]{0,1}(.*?)['"\>\s]}i;
	
	return $1;
}

sub regex_extract_number
{
	my $txt = shift;
	/()/;
	$txt =~ /(\d+)/;
	return $1;

}

sub regex_extract_date
{
	my $txt = shift;
	
	/()()()/;
	my ($month, $day, $year) = $txt =~ m{(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})}m;
	return convert_mdy_to_sql( $month, $day, $year);
}


sub find_regex_in_string
{
	my $find = shift;
	my $find_in = shift;
	my $count += () = $find =~ /\(/g;
	my $clear = '()'  x $count;
	/$clear/;
	my @f = $find_in =~ m/$find/;
	return @f;
}

sub uniq {
    return keys %{{ map { $_ => 1 } @_ }};
}


sub search_term_against_list
{
	my $term = shift;
	my @list = @{ (shift) };
	
#	print "$term\n";
	foreach my $l (@list)
	{
		$l =~ s/\n//g;
#		print " - $l : ".$term =~ /\b$l\b/si." : ".$term =~ /\b$l$/si;
		return $l if ( $term =~ /\b$l\b/si );
		return $l if ( $term =~ /\b$l$/si );
		return $l if ( $term =~ /\s$l\s/si );
	}
	
	return undef;
}

 
sub search_term_against_list_pure
{
	my $term = shift;
	my @list = @{ (shift) };
		
	foreach my $l (@list)
	{
#		print " - $l against $term: ".$term =~ m/$l/i."\n" ;
		return $l if ( $term =~ m/$l/i );
	}
	
	return undef;
}

sub phash
{
	my %h = %{(shift)};
	
	foreach my $k (keys %h)
	{
		printf "  - %-20s %-20s \n",
            $k, $h{$k} if ($h{$k} && $h{$k} ne '');
	}
	print "\n";
}

sub parray
{
	my @a = @{(shift)};
	
	foreach my $k (@a)
	{
		printf "  - %-20s  \n",
            $k if ($k  && $k ne '');
	}
	print "\n";
}

sub print_char_codes
{
	my $a = shift;
	if ( $a )
	{
		my @chars = split(//, $a);
		
	#	print "$a\n";
		foreach my $c (@chars)
		{
			print "$c -> ".ord($c)."\n";
		
		}
	}
}



#print_hash_sorted( dblspace = 0|1 )
sub print_hash
{
	print_hash_sorted (shift) ;

}
#print_hash_sorted( dblspace = 0|1 )
sub print_hash_sorted
{
	my %hash = %{ (shift) };
	my $dbl_space = shift;
	
	$dbl_space = 0 unless $dbl_space;
	my $line_delim = "\n";
	$line_delim = "\n\n" if ( $dbl_space != 0 );
	
	print "PRINTING HASH\n";
	print "\n";

	foreach my $key (sort (keys(%hash))) {
		printf "> %-30s %-20s $line_delim",
            $key, $hash{$key} if $hash{$key};
	}
	print "\n\n";

}

#print_hash_sorted( dblspace = 0|1 )
sub print_array
{
	my @ary = @{ (shift) };
	my $dbl_space = shift;
	
	$dbl_space = 0 unless $dbl_space;
	my $line_delim = "\n";
	$line_delim = "\n\n" if ( $dbl_space != 0 );
	
	print "PRINTING ARRAY\n";
	print "\n";

	foreach my $val (sort @ary ) {
		printf "> %-30s %-20s $line_delim",
            $val;
	}
	print "\n\n";

}

sub clean_tbl_for_view
{
	my $x = shift;
	$x =~ s/\s{1,}/ /gs;
	$x =~ s/<tr.*?>/<TR>/gs;
	$x =~ s/<td.*?>/<TD>/gs;
	$x =~ s/<TR>/\n<TR>/gsi;
	$x =~ s/<TD>/\n   <TD>/gsi;
	$x =~ s/<\/TR>/\n<\/TR>\n\n/gsi;

	print "\n---------------------------------------------------\n";
	print $x;
	print "\n---------------------------------------------------\n";
	
}



sub trim
{
	my $x = shift;
	$x =~ s/^\s{1,}//;
	$x =~ s/\s{1,}$//;
	$x =~ s/\s{1,}/ /;
	return $x;

}


# clean_small_date ( '01/01', year-'14' or '2014', fmt_for_sql?1=yes, custom_delminator, full_year?)
# clean small date - give us a 4/12 and will return 04/12 
# delim is / but is - if fmt_for_sql set.
# IF format_for_sql is true will return yyyy-mm-dd, if no year provided will warn then default to 
#  current year.
# If sql_format not set but year given will return mm/dd/yy (using custom delim
# If full_year_true is set, will force full year
sub clean_small_date
{
	my $date = shift;
	my $year = shift;
	my $sql_format_true = shift;
	my $delim = shift;
	my $full_year_true = shift;
	
		
	$delim = '-' if $sql_format_true;	#override
	$delim = '/' if ( !$delim );
	
	return unless $date =~ /\d{1,2}.\d{1,2}/;
	
	1 =~ /()()/;
	$date =~ /(\d{1,2})[-\/](\d{1,2})/;
	
	my $mo = $1;
	my $day = $2;
	
	if ( length($mo) == 1 )
	{
		$mo = '0'.$mo;
	}
	if ( length($day) == 1 )
	{
		$day = '0'.$day;
	}
	
	my $year_add = '';
	if ( $year )
	{
		$year_add = '' if ( length($year) == 0 );
		$year_add = '0'.$year if ( length($year) == 1 );
		$year_add = $year if ( length($year) == 2 );
		$year_add = '' if ( length($year) == 3 );
		$year_add = $year if ( length($year) == 4 );
		
		$year_add = substr( $year, 2, 2 ) if ( length( $year ) == 4 && !$full_year_true );
	}
	
	
	#if we have a len of 2 and we need sql style, then put the 19 or 20 in front, 1950-1999, 2000-2049
	if ( length($year_add) == 2 && ($sql_format_true || $full_year_true) )
	{
		if ( $year > 50 )	{
			$year_add = '19'.$year_add;	}
		else	{
			$year_add = '20'.$year_add;	}
	}
	
	my $return = $mo.$delim.$day;
	
	if ( $sql_format_true && $year_add )	{
		$return = $year_add."-".$return;	}
	
	elsif ( !$sql_format_true && $year_add )	{
		$return = $return.$delim.$year_add;		}
	
	elsif ( $sql_format_true && !$year_add )	{
		warn "No year provided, but one is needed for sql format. Assuming current year\n"; 
		
		my $currentyear = (localtime)[5] + 1900;
		$return = $currentyear."-".$return;
		print "$return\n(C/q)>";
		die unless <STDIN> =~ /^q/i;	
		}
			
	return $return;
}

sub remove_zero_from_date
{
	my $date = shift;
	$date =~ s/^0//;
	$date =~ s/0(\d[\/-])/\1/;
	
	$date =~ s/\d\d(\d\d)$/\1/;
	
	
	return $date;
}

sub trim_leading_zero
{
	my $val = shift;

	$val =~ s/^0{1,}//g;

	return $val;
}


sub add_leading_zeros
{
	my $var = shift;
	my $tgt_len = shift;
	
	$tgt_len = 2 if !$tgt_len;
	
	my $var_len = length($var);
	
	my $zeros_needed = $tgt_len - $var_len;
	
	my $lead = "0" x $zeros_needed;
	
		
	return $lead.$var;
}





sub test_col_vs_str_layout
{
	my @cols = @{( shift )};
	my $line = shift;
	my $delim = shift;
	
	$delim = ',' unless $delim;
	
	my @vals = split ( /$delim/, $line );
	
	for my $i (0 .. $#cols)
	{
		print "$cols[$i]  ->  $vals[$i]\n";
	}
	print "\n";
}


sub test_str_vs_str_layout
{
	my $cols_line = shift;
	my $line = shift;
	my $delim = shift;
	
	$delim = '[|,]' unless $delim;
	
	
	print "\nTEST STR vs STR LAYOUT\n";
	print "COLUMNS: $cols_line\n";
	print "VALUES: $line\n\n\n";
	
	my @cols = split ( /$delim/, $cols_line );
	my @vals = split ( /$delim/, $line );
	
	for my $i (0 .. $#cols)
	{
		print "$cols[$i]  ->  $vals[$i]\n";
	}
	print "\n";
}

#dump_array_to_file( $content, [name=$default_output_filename], [folder=$default_output_folder] )
#primarily used as a quick way to dump an html file to test, in conjuction with
#www::mechanize
sub dump_array_to_file
{
	my @c = @{( shift )};
	my $file_name = shift;
	my $folder = shift;
	
	
	$file_name = $default_output_filename unless $file_name;
	$folder = $default_output_folder unless $folder;
	
	$folder .= "\\" if ( $folder !~ /\\$/ );
	
	my $loc = $folder.$file_name;
	
	open OUT, ">$loc";
	foreach my $l (@c)
	{
		print OUT "$l\n";
	}
	close OUT;

}

#dump_to_file( $content, [name=$default_output_filename], [folder=$default_output_folder] )
#primarily used as a quick way to dump an html file to test, in conjuction with
#www::mechanize
sub dump_file
{
	my $c = shift;
	my $file_name = shift;
	my $folder = shift;
	
	
	$file_name = $default_output_filename unless $file_name;
	$folder = $default_output_folder unless $folder;
	
	if($^O =~ /MSWin/) {
		$folder .= "\\" if $folder !~ /\\$/ ;
	}else{
		$folder .= "/" if $folder !~ /\/$/ ;		
	}		
	
	my $loc = $folder.$file_name;
	
	open OUT, ">$loc" or die "Could not open $loc\n";
	print OUT $c;
	close OUT;

	print "\n\n*************************\nSAVED AT $loc\n";
}

#undump_file( [name=$default_output_filename], [folder=$default_output_folder] )
#primarily used as a quick way to get a dumped html file to test, in conjuction with
#www::mechanize.  Just call the method and itll retun the file as an array. 
sub undump_file
{
	my $file_name = shift;
	my $folder = shift;
	
	$file_name = $default_output_filename unless $file_name;
	$folder = $default_output_folder unless $folder;
	
	$folder .= "\\" if ( $folder !~ /\\$/ );
	
	my $loc = $folder.$file_name;
	
	open IN, "<$loc";
	my @f= <IN>;
	close IN;
	
	return @f;
}

#undump_file_str( $deliminator, [name=$default_output_filename], [folder=$default_output_folder] )
#primarily used as a quick way to get a dumped html file to test, in conjuction with
#www::mechanize.  Just call the method and itll retun the file as an array. 
#addition to undump_file that converts it to a string, with a user supplied deliminater 
#deliminator defaults to \n.
sub undump_file_str
{
	
	my $delim = shift;
	my $file_name = shift;
	my $folder = shift;
	
	$delim = "\n";
	
	my @file = undump_file( $file_name, $folder );
	
	return ( join ( $delim, @file ) );
} 




sub print_all_methods_in_package
{

	my $className = shift;
	$className = 'WWW::Mechanize' unless $className;
	print "symbols in $className:";

	eval "require $className";
	die "Can't load $className: $@" if $@;
	no strict 'refs';
	print skzz_util::print_hash_sorted(  \%{"main::${className}::"}  );
}

#Change cases
sub sentence_case
{
	my $x = shift;
	
	$x =~ tr/[A-Z]/[a-z]/;
	$x =~ m{^(.)(.*)};
	my $first = $1;
	my $sec = $2;
	$first =~ tr/[a-z]/[A-Z]/;
	
	return $first.$sec;

}

