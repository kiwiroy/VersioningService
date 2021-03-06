use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Deep;

use FindBin qw/$Bin/;
use lib "$Bin";
use TestDefaults;

use_ok 'Bio::EnsEMBL::Mongoose::Parser::DBASS';

my $reader =
  Bio::EnsEMBL::Mongoose::Parser::DBASS->new(source_file => "$ENV{MONGOOSE}/t/data/dbass.csv");
isa_ok($reader, 'Bio::EnsEMBL::Mongoose::Parser::DBASS');

my $num_of_records = 0;

# check first record
$reader->read_record;
my $record = $reader->record;
++$num_of_records;
is($record->id, 1, 'First record ID');
is($record->display_label, 'ABCD1', 'First record display label');
is($record->taxon_id, 9606, 'Correct tax id');
my $xrefs = $record->xref;
my $expected_xrefs = [ bless( {
			       'source' => 'Ensembl',
			       'creator' => 'DBASS',
			       'active' => 1,
			       'id' => 'ENSG00000101986'
			      }, 'Bio::EnsEMBL::Mongoose::Persistence::RecordXref' ) ];
cmp_deeply($xrefs, $expected_xrefs, "First record xrefs");
my $xref = shift $xrefs;
isa_ok($xref, "Bio::EnsEMBL::Mongoose::Persistence::RecordXref");

# seek to the middle of the file
for (1 .. 96) {
  $reader->read_record();
  ++$num_of_records;
}

my @expected_records = (
		{
		 id => 76,
		 display_label => 'GH-V',
		 xrefs => [ bless( {
				   'source' => 'Ensembl',
				   'creator' => 'DBASS',
				   'active' => 1,
				   'id' => 'ENSG00000136487'
				  }, 'Bio::EnsEMBL::Mongoose::Persistence::RecordXref' ) ]
		},
		{
		 id => 77,
		 display_label => 'GLA',
		 xrefs => [ bless( {
				   'source' => 'Ensembl',
				   'creator' => 'DBASS',
				   'active' => 1,
				   'id' => 'ENSG00000102393'
				  }, 'Bio::EnsEMBL::Mongoose::Persistence::RecordXref' ) ]
		},
		{
		 id => 174,
		 display_label => 'GNAT2',
		 xrefs => [ bless( {
				   'source' => 'Ensembl',
				   'creator' => 'DBASS',
				   'active' => 1,
				   'id' => 'ENSG00000134183'
				  }, 'Bio::EnsEMBL::Mongoose::Persistence::RecordXref' ) ]
		}
	       );

while ($num_of_records < 100) {
  $reader->read_record();
  my $got = $reader->record;
  ++$num_of_records;

  my $expected = shift @expected_records;
  is($got->id, $expected->{id}, 'Correct record id');
  is($got->display_label, $expected->{display_label}, 'Correct record display label');
  my $xrefs = $got->xref;
  cmp_deeply($got->xref, $expected->{xrefs}, "Correct xrefs");
}

note 'read all the records until the end of the file';
while ($reader->read_record()) {
  $record = $reader->record;
  ++$num_of_records;
}

ok(1, 'Reached end of file without dying');
is($num_of_records, 246, "Successfully read all $num_of_records records from file");

done_testing();
