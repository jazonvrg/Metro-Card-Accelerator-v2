#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Path qw(make_path);

my ($opt_file, $opt_report, $opt_help);
GetOptions(
    'f|file=s'  => \$opt_file,
    'r|report!' => \$opt_report,
    'h|help!'   => \$opt_help,
) or die "Use ./regress.pl -h for usage.\n";

if ($opt_help) { print_usage(); exit 0; }
my $cfg_file = defined($opt_file) ? $opt_file : 'regress.cfg';
my $cfg = parse_cfg($cfg_file);
if ($opt_report) {
    report_results($cfg);
    exit 0;
}
run_regression($cfg);
report_results($cfg);

sub parse_cfg {
    my ($file) = @_;
    open my $fh, '<', $file or die "Cannot open regression config '$file': $!\n";
    my %cfg = (
        cov => 'OFF', wave => 'ON', verbosity => 'UVM_LOW',
        pass_key_word => 'TEST PASSED', fail_key_word => 'TEST FAILED', tests => [],
    );
    my $in_list = 0;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*(?:#|\/\/|$)/;
        if (!$in_list) {
            if ($line =~ /^\s*cov\s*=\s*(\w+)/i) { $cfg{cov} = uc($1); next; }
            if ($line =~ /^\s*wave\s*=\s*(\w+)/i) { $cfg{wave} = uc($1); next; }
            if ($line =~ /^\s*pl\s*=\s*(\S+)/i) { $cfg{verbosity} = $1; next; }
            if ($line =~ /^\s*pass_key_word\s*=\s*"?([^"\r\n]+)"?\s*$/i) { $cfg{pass_key_word} = $1; $cfg{pass_key_word} =~ s/"//g; $cfg{pass_key_word} =~ s/^\s+|\s+$//g; next; }
            if ($line =~ /^\s*fail_key_word\s*=\s*"?([^"\r\n]+)"?\s*$/i) { $cfg{fail_key_word} = $1; $cfg{fail_key_word} =~ s/"//g; $cfg{fail_key_word} =~ s/^\s+|\s+$//g; next; }
            if ($line =~ /^\s*tc_list\s*\{/) { $in_list = 1; next; }
        } else {
            last if $line =~ /^\s*\}/;
            $line =~ s/\/\/.*$//;
            next if $line =~ /^\s*$/;
            if ($line =~ /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*run_times\s*=\s*(\d+)\s*,\s*run_opts\s*=\s*(.*?)\s*;?\s*$/) {
                my ($name, $times, $opts) = ($1, int($2), $3);
                $opts =~ s/;\s*$//;
                $opts =~ s/^\s+|\s+$//g;
                push @{$cfg{tests}}, { name => $name, times => $times, opts => $opts } if $times > 0;
            } else {
                die "Malformed testcase entry in $file: $line\n";
            }
        }
    }
    close $fh;
    die "No testcase entries found in $file\n" unless @{$cfg{tests}};
    $cfg{cov} = ($cfg{cov} eq 'ON') ? 'ON' : 'OFF';
    return \%cfg;
}

sub run_regression {
    my ($cfg) = @_;
    make_path('log');
    my $start = time();
    print "Regression build starting...\n";
    my $build_rc = system('make', 'build', "COV=$cfg->{cov}", "VERBOSITY=$cfg->{verbosity}");
    die "Build failed; regression stopped. See compiler output.\n" if $build_rc != 0;

    srand();
    for my $tc (@{$cfg->{tests}}) {
        for (1 .. $tc->{times}) {
            my $seed = int(rand(900000)) + 100000;
            print "\n============================================================\n";
            print "Running $tc->{name}, seed=$seed\n";
            print "============================================================\n";
            my @cmd = ('make', 'run', "TESTNAME=$tc->{name}", "SEED=$seed", "COV=$cfg->{cov}", "VERBOSITY=$cfg->{verbosity}");
            push @cmd, "RUNARG=$tc->{opts}" if length $tc->{opts};
            my $rc = system(@cmd);
            warn "Simulation command returned non-zero for $tc->{name} (seed $seed).\n" if $rc != 0;
        }
    }
    my $elapsed = time() - $start;
    print "Regression simulations complete in ${elapsed}s. Generating report...\n";
}

sub report_results {
    my ($cfg) = @_;
    make_path('log');
    my @logs = sort glob('log/*.log');
    my ($passed, $failed, $unknown) = (0, 0, 0);
    my @detail;
    for my $path (@logs) {
        next if $path =~ m{/(?:run|build|xrun|imc)\.log$};
        open my $fh, '<', $path or next;
        local $/; my $content = <$fh> // ''; close $fh;
        my $status = 'Unknown';
        if (index($content, $cfg->{fail_key_word}) >= 0 || $content =~ /UVM_(?:FATAL|ERROR)\s*:\s*[1-9]/) {
            $status = 'Failed'; $failed++;
        } elsif (index($content, $cfg->{pass_key_word}) >= 0) {
            $status = 'Passed'; $passed++;
        } else {
            $unknown++;
        }
        push @detail, sprintf("%-44s : %s\n", $path, $status);
    }
    open my $out, '>', 'regress.rpt' or die "Cannot write regress.rpt: $!\n";
    print $out "############################################################\n";
    print $out "####          Metro Card Regression Report             ####\n";
    print $out "############################################################\n";
    printf $out "Log files classified: %d\n", scalar(@detail);
    printf $out "Passed              : %d\n", $passed;
    printf $out "Failed              : %d\n", $failed;
    printf $out "Unknown             : %d\n", $unknown;
    print $out "------------------------------------------------------------\nRun log detail:\n";
    print $out @detail;
    print $out "------------------------------------------------------------\n";
    print $out "Note: only simulation logs with TEST PASSED / TEST FAILED markers are conclusive.\n";
    close $out;
    print "Report written to regress.rpt (passed=$passed failed=$failed unknown=$unknown).\n";
}

sub print_usage {
    print <<'USAGE';
Metro Card regression runner (ICTC UART-template style)
  ./regress.pl             Run all tests listed in regress.cfg
  ./regress.pl -f file.cfg Use a different regression config
  ./regress.pl -r          Regenerate regress.rpt from log/*.log
  ./regress.pl -h          Show this help
USAGE
}
