=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

=head1 NAME

Bio::EnsEMBL::Versioning::Pipeline::Downloader::UniProtTrembl

=head1 DESCRIPTION

A module for Trembl specific methods

=cut

package Bio::EnsEMBL::Versioning::Pipeline::Downloader::UniProtTrembl;

use Moose;

has uri => (
  isa => 'Str', 
  is => 'ro',
  default => 'ftp://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/knowledgebase/complete/',
);

has file_pattern => (
  isa => 'Str',
  is => 'rw', # to allow test runs
  default => 'uniprot_trembl.xml.gz',
);

has version_uri => ( 
  isa => 'Str', 
  is => 'ro', 
  default => 'ftp://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/relnotes.txt',
);
with 'Bio::EnsEMBL::Versioning::Pipeline::Downloader::FTPClient';
with 'MooseX::Log::Log4perl';

sub get_version
{
  my $self = shift;
  my $file = $self->do_FTP($self->version_uri);
  my $version;
  if ($file =~ m#UniProtKB/TrEMBL Release (\d+_\d+)#) {
    $version = $1;
  }
  Bio::EnsEMBL::Mongoose::NetException->throw('Failed to get version from Trembl release notes') unless $version;
  return $version;
}

sub _get_remote {
  my $self = shift;
  my $path = shift; # path is already checked as valid.

  my $result = $self->get_ftp_files($self->uri,$self->file_pattern,$path);
  $self->log->debug('Downloaded Trembl FTP files: '.join("\n",@$result));
  return $result if (scalar @$result > 0);
  Bio::EnsEMBL::Mongoose::NetException->throw("No files downloaded from Trembl source");
}
