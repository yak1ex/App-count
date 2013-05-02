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
	my @spec;
	my %opts = (
		c => sub { push @spec, ['count']; },
		s => sub { push @spec, map { ['sum', $_-1 ] } split /,/, $_[1]; },
	);
	GetOptionsFromArray(\@_, \%opts,
		'g|group=s@', 'c|count', 's|sum=s@', 'm|map=s@', 'M|map-file=s', 't|delimiter=s'
	);

	my $group = exists $opts{g} ? [map { $_ -1 } map { split /,/ } @{$opts{g}}] : undef;
	push @spec, ['count'] if ! @spec;
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

			foreach my $idx (0..$#spec) {
				$data{$key}[$idx] ||= 0;
				if($spec[$idx][0] eq 'count') {
					++$data{$key}[$idx];
				} else {
					$data{$key}[$idx] += $F[$spec[$idx][1]];
				}
			}
		}

		if($file ne '-') {
			close $fh;
		}

		foreach my $key (sort keys %data) {
			my @F;
			push @F, split /\x00/, $key if exists $opts{g};
			push @F, @{$data{$key}};
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
