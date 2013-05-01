package App::count;

use strict;
use warnings;

# ABSTRACT: Counting utility for a file consisting of the fixed number of fields like CSV
# VERSION

use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;

sub run
{
	shift if @_ && eval { $_[0]->isa(__PACKAGE__) };
	my %opts;
	GetOptionsFromArray(\@_, \%opts,
		'g|group=s@', 'c|count', 's|sum=s@', 'm|map=s@', 'M|map-file=s', 't|delimiter=s'
	);

	my $group = exists $opts{g} ? [map { $_ -1 } map { split /,/ } @{$opts{g}}] : undef;
	my $sum = exists $opts{s} ? [map { $_ -1 } map { split /,/ } @{$opts{s}}] : undef;
	$opts{c} = 1 if ! exists $opts{s};
	my $odelimiter = $opts{t} || "\t";
	$opts{t} ||= '\s+';

	push @_, '-' if ! @_;
	while(my $file = shift @_) {
		my $fh;
		if($file ne '-') {
			open $fh, '<', $file;
		} else {
			$fh = \*STDIN;
		}

		my %data;
		while(<$fh>) {
			s/[\r\n]+$//;
			my @F = split /$opts{t}/;

			my $key = defined $group ? join("\x00", @F[@$group]) : '_';
			++$data{$key}{count} if $opts{c};
			if(defined $sum) {
				foreach my $idx (0..$#$sum) {
					$data{$key}{sum}[$idx] ||= 0;
					$data{$key}{sum}[$idx] += $F[$sum->[$idx]];
				}
			}
		}

		if($file ne '-') {
			close $fh;
		}

		foreach my $key (keys %data) {
			my @F;
			push @F, split /\x00/, $key if exists $opts{g};
			push @F, $data{$key}{count} if exists $opts{c};
			push @F, @{$data{$key}{sum}} if exists $opts{s};
			print join($odelimiter, @F), "\n";
		}
	}
}

1;
__END__

=head1 SYNOPSIS

  App::count->run(@ARGV);

=head1 DESCRIPTION

This is an implementation module of a counting utility for a file consisting of the fixed number of fields.

=method C<run(@arg)>

Process arguments. Typically, C<@ARGV> is passed. For argument details, see L<installdeps>.

=head1 SEE ALSO

=for :list
* L<count>

=cut
