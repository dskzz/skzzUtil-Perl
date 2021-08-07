use strict;
use Data::Dumper;

my $file = 'd:\\tmp\\washington_legis_entry.csv';
open FILE, "<$file";

my @csv_lines = <FILE>;

close FILE;

my $header_line = shift @csv_lines;				#get the first row, which is the headers on the donor list
	$header_line =~s/[\n\r\f\e]//;					#clean new lines (esp needed for csv last entry)

my @headerfields = split(/,/, $header_line);		#split out the header fields

my %headers;
my $counter=0;
foreach my $h (@headerfields)
{
	$headers{$h} = $counter;
	$headers{$h}  =~ s/\n//;					#clean new lines (esp needed for csv last entry)
	$counter++;
}


	
foreach my $line_in_file (@csv_lines)
{
	$line_in_file =~ s/\n//g;
	my @cells = split /,/, $line_in_file;
	my %bank_hash;
		
	foreach my $key (keys %headers)
	{
		next if $key =~ /^x_/;
		next unless $cells[ $headers{$key} ];
		#$cells[ $headers{$key} ] = "\"".$cells[ $headers{$key} ]."\"" if ( $cells[ $headers{$key} ] ) =~ /\D/;
		$bank_hash{ $key } = $cells[ $headers{$key} ];
	}
	
	die Dumper convert_hashref_to_sql_param(\%bank_hash );

}



sub convert_hashref_to_sql_param
{
	my %hash = %{(shift)};
	my @stack;
	foreach my $key (keys(%hash))
	{
		my $val = $hash{$key};
		next if $val eq undef; 
		$val = "\"$val\"" if $val =~ /\D/; 	#use quotes if not a number
		$val = "\"\"" if $val eq ''; 	#use quotes if not a number
		push @stack,"$key=$val";
	}
	return join ",", @stack;
}



#THIS ASSIGNS THE HEADER HASH

#now we foreach and convert this shit
