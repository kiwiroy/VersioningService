package Bio::EnsEMBL::Mongoose::Persistence::Query;
use Moose::Role;

use Config::General;


# Config attributes are for legacy access of individual static indexes. Normally the broker should be consulted for this.
has config_file => (
    isa => 'Str',
    is => 'ro',
    default => sub {
        ## TODO FIXME BROKEN BROKEN BROKEN
        my $path = "$ENV{MONGOOSE}/conf/swissprot.conf";
        return $path;
    },
);

has config => (
    isa => 'HashRef',
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $conf = Config::General->new($self->config_file);
        my %opts = $conf->getall();
        return \%opts;
    },
);

has query_string => (
    isa => 'Str',
    is => 'rw',
);

has query_parameters => (
    isa => 'Bio::EnsEMBL::Mongoose::Persistence::QueryParameters',
    is => 'rw',
);

# Runs the supplied query through the query engine.
# Returns the result size if possible
sub query {
    
};


# Should iterate through results internally and emit the next result until there are no more.
sub next_result {
    
};

# Refers to a QueryParameters object to construct a suitable query in the diallect of choice.
sub build_query {
    
}

1;