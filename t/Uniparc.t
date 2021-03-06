use Modern::Perl;
use Test::More;
use Test::Differences;

use FindBin qw/$Bin/;
use lib "$Bin";
use TestDefaults;

use_ok 'Bio::EnsEMBL::Mongoose::Parser::Uniparc';

my $xml_reader = new Bio::EnsEMBL::Mongoose::Parser::Uniparc(
    source_file => "$ENV{MONGOOSE}/t/data/UPI0000000001.xml",
    top_tag => 'uniparc',
);

my $seq = "MGAAASIQTTVNTLSERISSKLEQEANASAQTKCDIEIGNFYIRQNHGCNLTVKNMCSADADAQLDAVLSAATETYSGLTPEQKAYVPAMFTAALNIQTSVNTVVRDFENYVKQTCNSSAVVDNKLKIQNVIIDECYGAPGSPTNLEFINTGSSKGNCAIKALMQLTTKATTQIAPKQVAGTGVQFYMIVIGVIILAALFMYYAKRMLFTSTNDKIKLILANKENVHWTTYMDTFFRTSPMVIATTDMQN";

$xml_reader->read_record;

my $record = $xml_reader->record;
is($record->accessions->[0], 'UPI0000000001', 'primary_accession check');
is($record->checksum, 'ef8a186543fe2e2243b5f2c571e8ce69', 'checksum check');
cmp_ok($record->sequence_length, '==', 250, 'sequence_length check');
cmp_ok(length($seq), '==', 250, 'other length check');
# Uniparc parser not keeping sequence, therefore no verification.
#is($record->sequence,$seq, 'Make sure sequence regex-trimming does no harm, but removes white space');

cmp_ok($record->count_xrefs, '==', 10, 'Record has ten active xrefs');
$xml_reader->read_record;
$record = $xml_reader->record;
#print ref($record->xref)."\n";
#print dump($record);
#print "Xrefs ".scalar(@{$record->xref})."\n";
my @xrefs = @{$record->xref};
cmp_ok(scalar @{$record->xref}, '==', 2, 'Second record has only two active xrefs');

ok(!$xml_reader->read_record, 'Check end-of-file behaviour. Reader should return false.');

done_testing;
