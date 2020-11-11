package Health::BladderDiary::GenTable;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use HTML::Entities;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_bladder_diary_table_from_entries);

our %SPEC;

$SPEC{gen_bladder_diary_table_from_entries} = {
    v => 1.1,
    summary => 'Create bladder diary table from bladder diary entries',
    args => {
        entries => {
            schema => 'str*',
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_file',
        },
    },
};
sub gen_bladder_diary_table_from_entries {
    my %args = @_;

    my $entries = $args{entries};
    my @urinations;
    my @fluid_intakes;

    my $i = 0;
    for my $para (split /\R\R+/, $entries) {
        my $para0 = $para;
        $i++;
        my $time;
        $para =~ s/\A(\d\d)[:.]?(\d\d)\s*// or return [400, "Paragraph $i of entries: invalid time, please start with hhmm or hh:mm: $para0"];
        my ($h, $m) = ($1, $2);
        $para =~ s/(\w+):?\s*// or return [400, "Paragraph $i of entries: event (e.g. drink, urinate) expected: $para"];
        my $event = $1;
        $event =~ /\A(drink|eat|poop|urinate|comment)\z/ or return [400, "Paragraph $i of entries: unknown event '$event', please choose eat|drink|poop|urinate|comment"];

        my $vol;
        if ($event eq 'drink' || $event eq 'urinate') {
            my $entry = {
                time => $h*60 + $m,
            };

            $para =~ /\b(\d+)ml\b/ or return [400, "Paragraph $i of entries ($event): volume not found, please use 123ml as format"];
            $vol = $1;

            my %kv;
            while ($para =~ /(\w+)=(.+?)(?=\s+\w+=|\s*\z)/g) {
                $kv{$1} = $2;
            }

            for my $k (qw/comment urgency color/) {
                if (defined $kv{$k}) {
                $entry->{$k} = $kv{$k};
            }

            if ($event eq 'drink') {
                push @fluid_intakes, $entry;
            } else {
                push @urinations, $entry;
            }
        }
    }
    [200, "OK", {fluid_intakes=>\@fluid_intakes, urinations=>\@urinations}];
}

1;
# ABSTRACT: Create bladder diary table from entries

=head1 SYNOPSIS

Your bladder entries e.g. in `bd-entry1.txt` (I usually write in Org document):

 0730 drink: 300ml type=water

 0718 urinate: 250ml

 0758 urinate: 100ml

 0915 drink 300ml

 1230 drink: 600ml, note=thirsty

 1245 urinate: 200ml

From the command-line (I usually run the script from inside Emacs):

 % gen-bladder-diary-table-from-entries < bd-entry1.txt
 | time    | intake type | itime | ivol (ml) | ivol cum | icomment | urination time | uvol (ml) | uvol cum | urgency (0-3) | ucolor (0-3) | ucomment |
 |---------+-------------+-------+-----------+----------+----------+----------------+-----------+----------+---------------+--------------+----------+
 | 07-08am | water       | 07.30 |       300 |      300 |          |          07.18 |       250 |      250 |               |              |          |
 |         |             |        |           |          |          |          07.58 |       100 |      350 |               |              |          |
 | 08-09am |             |       |           |          |          |                |           |          |               |              |          |
 | 09-10am | water       | 09.15 |       300 |      600 |          |                |           |          |               |              |          |
 | 10-11am |             |       |           |          |          |                |           |          |               |              |          |
 | 12-01pm | water       | 12.30 |       600 |     1200 | thirsty  |          12.45 |       200 |          |               |              |          |
 |         |             |       |           |          |          |                |           |          |               |              |          |
 | total   |             |       |      1200 |          |          |                |       550 |          |               |              |          |
 | freq    |             |       |         3 |          |          |                |         3 |          |               |              |          |
 | avg     |             |       |       400 |          |          |                |       183 |          |               |              |          |

Produce CSV instead:

 % gen-bladder-diary-table-from-entries --format csv < bd-entry1.txt > bd-entry1.csv


=head1 DESCRIPTION

This script is

=head1 SEE ALSO
