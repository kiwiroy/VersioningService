# Test the REST interface against ensembl REST server
use Test::More;
use Moose;
use Bio::EnsEMBL::Versioning::Pipeline::Downloader::HTTPClient;
use Data::Dumper;
use Cwd;

package Thingy;

use Moose;
with 'Bio::EnsEMBL::Versioning::Pipeline::Downloader::HTTPClient';

package main;

my $http_client = Thingy->new;
my $test_host_url = "http://www.reactome.org/download/";
my $status = $http_client->connected_to_http($test_host_url);
ok($status, "Able to connect to $test_host_url");

my $file_names = ["mapping.README.txt"];
my $downloaded_files = $http_client->get_http_files(host_URL=>$test_host_url, filenames=>$file_names);
isa_ok($downloaded_files, 'ARRAY' );
ok(scalar(@$downloaded_files) == 1, "Got back 1 files");
ok($$downloaded_files[0] eq cwd().'/mapping.README.txt', "Got back the right file");
ok(-e cwd().'/mapping.README.txt', "File exists at ". cwd().'/mapping.README.txt');

clean_up_files($downloaded_files);

ok(! -e cwd().'/mapping.README.txt', "File do not exist at ". cwd().'/mapping.README.txt');

sub clean_up_files {
  my $downloaded_files = shift;
  foreach my $file (@$downloaded_files){
    unlink $file;
  }

}


done_testing;