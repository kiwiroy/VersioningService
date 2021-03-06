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

=head1 DESCRIPTION

IndexReader provides an iterator interface targetted interface to Lucy indexes for extracting records.
Records from the index are automatically vivified into a Record object

=head1 SYNOPSIS

# Unless a filehandle or path is specified, the output will go to STDOUT
my $search = Bio::EnsEMBL::Mongoose::IndexReader->new(
  storage_engine_conf_file => $ENV{MONGOOSE}.'./conf/manager.conf'
);

my $source_list = $mfetcher->versioning_service->get_active_sources;

my $params = Bio::EnsEMBL::Mongoose::Persistence::QueryParameters->new(
    taxons => [9606]
);

foreach my $source (@$source_list) {
  $search->work_with_index(source => $source->name);
  $search->query_params($params);
  while (my $record = $search->next_record()) {
    ...
  }
}
# See also Bio::EnsEMBL::Mongoose::Persistence::QueryParameters for other kinds of filtering

=cut
package Bio::EnsEMBL::Mongoose::IndexReader;

use Moose;
use Moose::Util::TypeConstraints;
use Method::Signatures;

# In future this module should not be tightly tied to Apache Lucy, but allow
# any document store to queried in this fashion, at least within the Lucene family.
use Bio::EnsEMBL::Mongoose::Persistence::LucyQuery;
use Bio::EnsEMBL::Mongoose::Persistence::QueryParameters;
use Bio::EnsEMBL::Mongoose::Taxonomizer;
use Bio::EnsEMBL::Versioning::Broker;

use Bio::EnsEMBL::Mongoose::SearchEngineException;
use Bio::EnsEMBL::Mongoose::IOException;
use Bio::EnsEMBL::Mongoose::UsageException;

# Contains information about the index Lucy will use, either by file or hash.
has storage_engine_conf_file => ( isa => 'Str', is => 'rw', predicate => 'using_conf_file', trigger => \&_validate_path);

sub _validate_path {
  my ($self,$new_value,$old_value) = @_;
  if ($new_value) {
    $self->log->debug("Changing config file from $new_value to $new_value");
  }
  if ($new_value) {
    Bio::EnsEMBL::Mongoose::IOException->throw('Cannot configure IndexReader due to unreadable config file: $new_value') unless (-r $new_value);
  } 
}

has storage_engine_conf => (isa => 'HashRef', is => 'rw');
has index_conf => ( isa => 'HashRef', is => 'rw');
has storage_engine => (
    isa => 'Bio::EnsEMBL::Mongoose::Persistence::LucyQuery',
    is => 'ro',
    lazy => 1,
    builder => '_init_storage',
);

sub _init_storage {
    my $self = shift;
    my $store;
    my %opts;
    if ($self->using_conf_file) {
        $self->log->debug("Reading config file ".$self->storage_engine_conf_file);
        my $conf = Config::General->new($self->storage_engine_conf_file);
        %opts = $conf->getall();
        if (ref $opts{index_location} ne 'ARRAY') {
          $opts{index_location} = [$opts{index_location}];
        }
        $self->storage_engine_conf(\%opts);
        if (exists $opts{index_location}) {
            $self->index_conf({index_location => $opts{index_location}, data_location => $opts{data_location} });
        }
    } else {
      unless (defined $self->index_conf) {
        Bio::EnsEMBL::Mongoose::UsageException->throw("Cannot access index unless a storage_engine_conf_file is given, or index_conf is set directly with key 'index_location'.");
      }
      %opts = %{$self->index_conf};
    }
    $self->log->debug("Activating Lucy index ".join (',', @{ $opts{index_location} }) ); 
    $store = Bio::EnsEMBL::Mongoose::Persistence::LucyQuery->new(config=>$self->index_conf);
    return $store;
}

has species => (isa => 'Str', is => 'rw',default => 'human');
has source => (isa => 'Str', is => 'rw',default => 'UniProt/SWISSPROT');

has query_params => (
    isa => 'Object',
    is => 'rw',
    builder => '_populate_query_object',
    lazy => 1,
);

sub _populate_query_object {
    my $self = shift;
    my $taxon = $self->taxonomizer->fetch_taxon_id_by_name($self->species);
    unless ($taxon) { Bio::EnsEMBL::Mongoose::SearchEngineException->throw("Search for ".$self->species." didn't return any taxa, no query can be made without a taxon") }
    my $query = Bio::EnsEMBL::Mongoose::Persistence::QueryParameters->new(
        taxons => [$taxon],
    );
    return $query;
}

has versioning_service => (
    isa => 'Bio::EnsEMBL::Versioning::Broker',
    is => 'ro',
    lazy => 1,
    predicate => 'versioning_service_ready',
    builder => '_awaken_giant',
);

sub _awaken_giant {
    my $self = shift;
    my $broker = Bio::EnsEMBL::Versioning::Broker->new();
    return $broker;
}

has taxonomizer => (
    isa => 'Bio::EnsEMBL::Mongoose::Taxonomizer',
    is => 'ro',
    lazy => 1,
    default => sub {
        return Bio::EnsEMBL::Mongoose::Taxonomizer->new;
    }
);

has refer_to_blacklist => (
    isa => 'Bool',
    is => 'rw',
    traits => ['Bool'],
    default => 0,
    handles => {
        use_blacklist => 'set',
        ignore_blacklist => 'unset',
    }
);

has blacklist => (
    isa => 'HashRef[Str]',
    is => 'rw',
    lazy => 1,
    builder => '_build_blacklist',
    traits => ['Hash'],
    handles => {
        clear_blacklist => 'clear',
    }
);

has blacklist_source => (
    isa => 'Str',
    is => 'rw',
    lazy => 1,
    default => '',
);

has isoforms => (
    isa => 'Bool',
    is => 'rw',
    default => 0,
    traits => ['Bool'],
    handles => {
        include_isoforms => 'set',
        ignore_isoforms => 'unset'
    }
);

with 'MooseX::Log::Log4perl';


sub _build_blacklist {
    my $self = shift;
    my $fh = IO::File->new($self->blacklist_source) 
        || Bio::EnsEMBL::Mongoose::IOException->throw( message => "Couldn't open supplied blacklist ".$self->blacklist_source);
    while (my $banned = <$fh>) {
        chomp($banned);
        $self->blacklist->set($banned => 1);
    }
    $self->use_blacklist;
}

# Could be a simple iterator, but this allows a degree of filtering of the result set
sub next_record {
    my $self = shift;

    my $result = $self->storage_engine->next_result;
    return unless $result;
    my $record = $self->storage_engine->convert_result_to_record($result);
    
    if ($self->refer_to_blacklist) {
        my @accessions;
        @accessions = @{$record->accessions} if $record->accessions;
        foreach my $accession (@accessions) {
            if ($self->blacklist->exists($accession)) {
              next; 
              $self->log->debug('Skipping blacklisted id: '.$accession)
            }
        }
    }
    return $record;
}

sub how_many_hits {
  my $self = shift;
  if (!$self->storage_engine->mid_query) { 
      $self->storage_engine->query_parameters($self->query_params);
      $self->storage_engine->query();
  }
  return $self->storage_engine->result_set->total_hits;
}

sub convert_name_to_taxon {
    my $self = shift;
    my $name = $self->query_params->species_name;
    my $taxon = $self->taxonomizer->fetch_taxon_id_by_name($name);
    unless ($taxon) {
        Bio::EnsEMBL::Mongoose::SearchEngineException->throw(
            message => 'Supplied species name '.$name.' did not translate to a taxon, check spelling versus NCBI taxonomy.',
        );
    }
    $self->query_params->taxons([$taxon]);
}

method work_with_index ( Str :$source, Str :$version? ) {
  # unless ($self->versioning_service_ready() ) { Bio::EnsEMBL::Mongoose::SearchEngineException->throw('Versioning service not initialised.') }
  my $paths = $self->versioning_service->get_index_by_name_and_version($source,$version);
  # TODO branch to polysearcher here if necessary
  $self->log->debug(sprintf "Switching to index: %s from source %s and version %s",join (',',@$paths), $source, $version);
  $self->index_conf({ index_location => $paths, source => $source, version => $version});
  $self->storage_engine();
  $self->source($source);
}

method work_with_run ( Str :$source, Str :$run_id) {
  my $version = $self->versioning_service->get_version_for_run_source($run_id,$source);
  unless ($version) {
    Bio::EnsEMBL::Mongoose::SearchEngineException->throw("Run ID $run_id and source $source cannot be found in versioning service");
  }
  my $paths = $version->get_all_index_paths;
  $self->index_conf({ index_location => $paths, source => $source, version => $version->revision});
  $self->storage_engine();
  $self->source($source);
}

# Useful when triggering a query when the parameters were provided elsewhere, but not yet fetching the results. Awakes lazy-loaders downstream
sub prep_query {
  my $self = shift;
  $self->storage_engine->query_parameters($self->query_params);
  $self->storage_engine->query();
}

# Note no return value. For that there is next_record();
# QueryParameters object is sent to the query engine, and the results can be retrieved with next_record()
sub query {
  my $self = shift;
  my $query_params = shift;
  if (!ref $query_params eq 'Bio::EnsEMBL::Mongoose::Persistence::QueryParameters') {
    Bio::EnsEMBL::Mongoose::SearchEngineException->throw('Usage requires a QueryParameters object passed as a parameter');
  }
  $self->query_params($query_params);
  $self->convert_name_to_taxon if $query_params->species_name;
  # Ideally one would not repeatedly convert species name to taxon over and over...
  $self->prep_query;
}


__PACKAGE__->meta->make_immutable;

1;
