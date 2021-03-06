use Modern::Perl;
use Test::More;
use Test::Differences;

use FindBin qw/$Bin/;
use lib "$Bin";
use TestDefaults;

use_ok 'Bio::EnsEMBL::Mongoose::Parser::RefSeq';


my $source = $ENV{MONGOOSE}."/t/data/XM_005579308.gbff";
my $ref_seq_reader = Bio::EnsEMBL::Mongoose::Parser::RefSeq->new(
    source_file => $source,
);

$ref_seq_reader->read_record;

my $record = $ref_seq_reader->record;
# print dump($record);
my $accessions = $record->accessions;
# note(scalar @$accessions);
is($record->accessions->[0], 'XM_005579308', 'primary_accession check');
cmp_ok($record->sequence_length, '==', 6102, 'sequence_length check');
is($record->taxon_id, '9541','Taxon correctly extracted');
is($record->id, 'XM_005579308','ID correctly extracted');
is($record->gene_name, '102137896','NCBIGene name correctly extracted');
# is($record->entry_name, 'CTSC','Gene name correctly extracted');
cmp_ok(length($record->comment), '==', 665, 'Check comment block extracted whole as an array');

# Feature extraction

is_deeply([map { $_->id } @{$ref_seq_reader->record->xref}],['GeneID:102137896'] , 'Entrezgene/NCBIGene ID extracted from feature block');
is($record->protein_name,'XP_005579365.1', 'Where possible a protein accession is extracted from CDS entries');
# Next/last record
$ref_seq_reader->read_record;
#print ref($record->xref)."\n";
#print dump($record);
#print "Xrefs ".scalar(@{$record->xref})."\n";
ok(!$ref_seq_reader->read_record, 'Check end-of-file behaviour. Reader should return false.');

$ref_seq_reader = undef;

$source = $ENV{MONGOOSE}."/t/data/YP_001693987.gpff";
$ref_seq_reader = Bio::EnsEMBL::Mongoose::Parser::RefSeq->new(
    source_file => $source,
);
# Third record
$ref_seq_reader->read_record;
$accessions = $record->accessions;
# No accession found in certain micro-organisms
# is($record->accessions->[0], 'YP_001693987','Testing Refseq GPFF file');

my $evidence = $ref_seq_reader->determine_evidence('XM_005579308');
is_deeply($evidence, ['predicted','mRNA'], 'Evidence extraction from accession');
$evidence = $ref_seq_reader->determine_evidence('XP_005579308');
is_deeply($evidence, ['predicted','protein'], 'Evidence extraction from accession');

# Check gene name extraction from a troublesome record

$ref_seq_reader = undef;

$source = $ENV{MONGOOSE}."/t/data/NM_001308190.gbff";
$ref_seq_reader = Bio::EnsEMBL::Mongoose::Parser::RefSeq->new(
    source_file => $source,
);

$ref_seq_reader->read_record;
$record = $ref_seq_reader->record;

is($record->gene_name, '2993', 'Gene ID for GYPA found in NM_001308190');
is($record->display_label, 'GYPA', 'GYPA assigned to display_label in NM_001308190');

done_testing;
