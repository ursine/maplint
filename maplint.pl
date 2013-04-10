#!/usr/bin/perl -w 

# Load up modules
use strict;

# Check to make sure that a room file actually is valid

my %rooms      = ();
my $state      = 0; # Indicator of the current state of the parser
my $counter    = 0;
my $roominfo   = undef;
my $roomname   = "";
my $roomtext   = "";
my $exits      = [];
my @errors     = ();

# Statistical
my $totalrooms = 0;
my $bytesize   = 0;

# Parse through the room files and seperate it out into rooms, and links
# to rooms...

&credits();

print "Processing the rooms file:";

while (<>) {

	chomp;
	my $line = $_; # Get a real variable to work with
	$bytesize+=length($line);

	$counter++;

	if ($state == 0) { # Expect a #, start of a new room
		if ($line =~ /^#$/) {
			print ".";
			$state    = 1;
			$roominfo = {}; # build a new anonymous array
			$roomtext = "";
			$exits    = [];
			next;
		}
	        push @errors,"File format error on line $counter of $ARGV.";
		last;
	}

	if ($state == 1) { # Room name
		$roomname = "main.$line";

		if ($line =~ /^#$/) {
			push @errors,"Bogus room name \"#\" at $counter of $ARGV.";
			next;
		}

		if (exists $rooms{$roomname}) {
			push @errors,"Duplicate room warning on line $counter of $ARGV. The Original at line ".$rooms{$roomname}->{line}.".\n";
		}

		$rooms{$roomname}=$roominfo;
		$rooms{$roomname}->{name}=$roomname;
		$rooms{$roomname}->{line}=$counter;
		$state=2;
		next;
	}

        if ($state == 2) { # where message
		$rooms{$roomname}->{where}=$line;
		$state=3;
		next;
	}

	if ($state == 3) {
		$rooms{$roomname}->{entermsg}=$line;
		$state = 4;
		next;
	}

	if ($state == 4) {
		if ($line =~ /^#$/) {
			$state = 5;
			$rooms{$roomname}->{text}=$roomtext;
			next;
		} 
		$roomtext.=$line;
		next;
	}

	if ($state == 5) {
		if ($line =~ /^end$/) {
			$state = 6;
			$rooms{$roomname}->{exits}=$exits;
			next;
		}
		push @$exits,$line;
		next;
	}

	if ($state == 6) {
		if ($line =~ /^end$/) {
			$state = 0;
			$totalrooms++;
			next;
		}
	}

}

# Next level of postprocessing

for my $each_room (sort keys %rooms) {
	my @exits = @{$rooms{$each_room}->{exits}};

	push (@errors, "Orphan room $each_room") if (scalar @exits == 0);

	for my $test_room (@exits) {
	   push (@errors, "Bogus room link $test_room in $each_room") unless (exists $rooms{$test_room});
	}

}

# Display information about the rooms

print "\n\n";

print join "\n",@errors;

print "\n\n";

statistics();


# Subroutines

sub credits {
	print "\nMaplint (C) 2001  Gary Coulbourne (bear\@bears.org)\n";
	print "       Playground+ rooms file linting program\n";
	print "This program is licensed under the terms of the GPL\n";
	print "                   --=* *=--\n\n";
}

sub statistics {
	print "\n";
	print "Statistics\n";
	print "----------\n";
	print "Total number of lines      : $counter\n";
	print "Total number of characters : $bytesize\n";
	print "Total number of rooms      : $totalrooms\n";
	print "\n";
}

sub xml_header {
	print "<?xml?>\n";
	print "<sets>\n";
}	

sub xml_footer {
	print "</sets>\n";
}
