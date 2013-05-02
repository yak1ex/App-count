use Test::More;
use App::count;

sub check
{
	pipe(FROM_PARENT, TO_CHILD);
	pipe(FROM_CHILD, TO_PARENT);
	my $pid = fork;
	die "fork failed: $!" if ! defined($pid);
	if($pid) {
		close FROM_PARENT;
		close TO_PARENT;
		print TO_CHILD $_[1];
		close TO_CHILD;
		local $/ = undef;
		my $output = <FROM_CHILD>;
		close FROM_CHILD;
		is($output, $_[2], $_[3]);
		waitpid $pid, 0;
	} else {
		close FROM_CHILD;
		close TO_CHILD;
		open STDIN, "<&FROM_PARENT";
		open STDOUT, ">&TO_PARENT";
		App::count->run(@{$_[0]});
		close FROM_PARENT;
		close TO_PARENT;
		exit;
	}
}

my @tests = (
	[
		[], <<EOF,
1	2	3
1	1	1
2	3	1
3	1	2
EOF
		<<EOF,
4
EOF
		'no argument'		
	],
);

plan tests => scalar @tests;
check(@$_) for @tests;
