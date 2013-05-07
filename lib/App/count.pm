package App::count;

use strict;
use warnings;

# ABSTRACT: Counting utility for a file consisting of the fixed number of fields like CSV
# VERSION

use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage;
use YAML::Any;

Getopt::Long::Configure('posix_default', 'no_ignore_case');

sub run
{
	shift if @_ && eval { $_[0]->isa(__PACKAGE__) };
	my @spec;
	my $handler = sub { my $key = $_[0]; push @spec, map { [$key, $_-1 ] } split /,/, $_[1]; };
	my %opts = (
		c => sub { push @spec, ['count']; },
		sum => $handler, max => $handler, min => $handler, avg => $handler,
		'map' => sub {
			my @t = split /,/, $_[1];
			while(my ($idx, $key) = splice(@t, 0, 2)) {
				push @spec, ['map', $idx-1, $key];
			}
		}
	);
	GetOptionsFromArray(\@_, \%opts,
		'g|group=s@', 'c|count', 'sum|s=s@', 'map|m=s@', 'M|map-file=s', 't|delimiter=s',
		'max=s@', 'min=s@', 'avg|ave=s@',
		'h', 'help',
	) or pod2usage(-verbose => 0);
	pod2usage(-verbose => 0) if exists $opts{h};
	pod2usage(-verbose => 2) if exists $opts{help};

	my $map;
	$map = YAML::Any::LoadFile($opts{M}) or die "Can't load map file" if exists $opts{M};
	my $group = exists $opts{g} ? [map { $_ -1 } map { split /,/ } @{$opts{g}}] : undef;
	push @spec, ['count'] if ! @spec;
	my $odelimiter = $opts{t} || "\t";
	$opts{t} ||= '\s+';

	my %init = (
		max => sub { undef },
		min => sub { undef },
		avg => sub { [0,0] }, # Return new array reference
		sum => sub { 0 },
		count => sub { 0 },
		'map' => sub { undef },
	);

	push @_, '-' if ! @_;
	while(my $file = shift @_) {
		my $fh;
		if($file ne '-') {
			open $fh, '<', $file;
		} else {
			$fh = \*STDIN;
		}

		my %data;
		my %proc = ( # $key, $idx, \@F
			max   => sub { my ($key, $idx, $F) = @_; $data{$key}[$idx] = $F->[$spec[$idx][1]] if ! defined $data{$key}[$idx] || $data{$key}[$idx] < $F->[$spec[$idx][1]]; },
			min   => sub { my ($key, $idx, $F) = @_; $data{$key}[$idx] = $F->[$spec[$idx][1]] if ! defined $data{$key}[$idx] || $data{$key}[$idx] > $F->[$spec[$idx][1]]; },
			avg   => sub { my ($key, $idx, $F) = @_; ++$data{$key}[$idx][0]; $data{$key}[$idx][1] += $F->[$spec[$idx][1]]; },
			sum   => sub { my ($key, $idx, $F) = @_; $data{$key}[$idx] += $F->[$spec[$idx][1]]; },
			count => sub { my ($key, $idx, $F) = @_; ++$data{$key}[$idx]; },
			'map' => sub { my ($key, $idx, $F) = @_; $data{$key}[$idx] ||= $map->{$spec[$idx][2]}{$F->[$spec[$idx][1]]}; },
		);
		while(<$fh>) {
			s/[\r\n]+$//;
			my @F = split /$opts{t}/;

			my $key = defined $group ? join("\x00", @F[@$group]) : '_';

			foreach my $idx (0..$#spec) {
				$data{$key}[$idx] ||= $init{$spec[$idx][0]}->();
				$proc{$spec[$idx][0]}->($key, $idx, \@F);
			}
		}

		if($file ne '-') {
			close $fh;
		}

		foreach my $key (sort keys %data) {
			my @F;
			push @F, split /\x00/, $key if exists $opts{g};
			push @F, map { ref $_ ? $_->[1]/$_->[0] : $_ } @{$data{$key}};
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

Process arguments. Typically, C<@ARGV> is passed. For argument details, see L<count>.

=head1 SEE ALSO

=for :list
* L<count>

=cut
