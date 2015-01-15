# Superclass of things that get data from specific source indexes and turn them into triples.
# Convenience methods supplied for writing RDF swiftly (i.e. not through a library)

package Bio::EnsEMBL::Mongoose::Serializer::RDFLib;

use Moose;
use namespace::autoclean;

has namespace => (
  traits => ['Hash'],
  is => 'ro',
  isa => 'HashRef',
  default => sub { {
    ensembl => 'http://rdf.ebi.ac.uk/resource/ensembl/',
    ensemblterm => 'http://rdf.ebi.ac.uk/terms/ensembl/',
    ensemblsource => 'http://rdf.ebi.ac.uk/resource/ensembl/source',
    rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
    rdfg => 'http://www.w3.org/2004/03/trix/rdfg-1/',
    # RDF graph descriptions.. subgraph etc.
    owl => 'http://www.w3.org/2002/07/owl#',
    dcterms => 'http://purl.org/dc/terms/identifier',
    obo => 'http://purl.obolibrary.org/obo/',
    # obo includes sequence ontology for some reason
    sio => 'http://semanticscience.org/resource/',
    faldo => 'http://biohackathon.org/resource/faldo',
    uniprotswissprot => 'http://purl.uniprot.org/uniparc/',
    uniprottrembl => 'http://purl.uniprot.org/uniparc/',
    uniprotuniparc => 'http://purl.uniprot.org/uniparc/',
    embl => 'http://www.embl.de/',
    refseq => 'www.ncbi.nlm.nih.gov/refseq/',
    go => 'http://purl.obolibrary.org/obo/',
    chembl => 'http://rdf.ebi.ac.uk/resource/chembl/target/',
    entrezgene => 'http://identifiers.org/ncbigene/',
    protein_id => 'http://identifiers.org/insdc/',
    goslim_goa => 'http://purl.obolibrary.org/obo/',

  } },

);

# list of canonical URIs for particular data providers resolved through idtype.indentifiers.org . Best practice.
has identifiers => (
  traits => ['Hash'],
  is => 'ro',
  isa => 'HashRef',
  default => sub {
    {
      ccds => 'ccds',
      chembl => 'chembl.target',
      embl => 'ena.embl',
      ensembl => 'ensembl',
      entrezgene => 'ncbigene',
      go => 'go',
      goa => 'goa',
      hgnc => 'hgnc',
      interpro => 'interpro',
      refseq => 'refseq',
      uniparc => 'uniparc',
      uniprotswissprot => 'uniprot',
      uniprottrembl => 'uniprot',
    }
  },

  );

has handle => (is => 'rw', isa => 'IO::File', required => 1);
has bnode => ( is => 'rw', traits => ['Counter'], isa => 'Int', default => 0, handles => {bplus => 'inc'});

with 'MooseX::Log::Log4perl';

sub prefix {
  my $self = shift;
  my $source = shift;
  $source = lc $source;
  if ( exists $self->namespace->{$source}) { return $self->namespace->{$source} }
  else { 
    $self->log->debug('Failed to match source '.$source.' with namespace');
    return $self->namespace->{ensembl}.'source/';
  }
}

sub identifier {
  my $self = shift;
  my $source = shift;
  $source = lc $source;
  if (exists $self->identifiers->{$source}) { return 'http://identifiers.org/'.$self->identifiers->{$source} }
  else {
    $self->log->debug("No identifiers.org standard path available for $source");
    return "http://identifiers.org/general/$source";
  }
}

sub triple {
  my $self = shift;
  my ($subject,$predicate,$object) = @_;
  return sprintf "%s %s %s .\n",$subject,$predicate,$object;
}

sub u {
  my $self = shift;
  my $stuff= shift;
  return '<'.$stuff.'>';
}

sub new_bnode {
  my $self = shift;
  $self->bplus();
  return '_'.$self->bnode;
}


sub dump_prefixes {
  my $self = shift;
  my $fh = $self->handle;
  my %namespaces = %{$self->namespace};
  foreach my $key (keys %namespaces) {
    print $fh triple('@prefix',$key.':',u($namespaces{$key}) );
  }
}

__PACKAGE__->meta->make_immutable;

1;