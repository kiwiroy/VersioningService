=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

=pod


=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=head1 NAME

Bio::EnsEMBL::Versioning::Pipeline::CollateIndexes

=head1 DESCRIPTION

Given a folder full of files, generate a fan of one job per file
Also potentially branch to alternative resource classes for unusually sized jobs

=cut

package Bio::EnsEMBL::Versioning::Pipeline::CollateIndexes;

use strict;
use warnings;
use Bio::EnsEMBL::Versioning::Broker;

use parent qw/Bio::EnsEMBL::Versioning::Pipeline::Base/;

sub run {
  my ($self) = @_;

  my $source_name = $self->param('source'); # This comes from an accumulator

  my $broker = Bio::EnsEMBL::Versioning::Broker->new;
  my $latest_version = $broker->get_version_of_source($source_name,$version);
  $broker->set_current_version_of_source( $source_name, $latest_version->revision);
  
  return;
}



1;