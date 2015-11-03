use utf8;
package Bio::EnsEMBL::Versioning::ORM::Schema::Result::Source;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Bio::EnsEMBL::Versioning::ORM::Schema::Result::Source

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<source>

=cut

__PACKAGE__->table("source");

__PACKAGE__->add_columns(
  "source_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "source_group_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "active",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "created_date",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "downloader",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "parser",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "current_version",
  { data_type => "integer", is_nullable => 1, extra => { unsigned => 1 } },
);

__PACKAGE__->set_primary_key("source_id");

__PACKAGE__->add_unique_constraint("name_idx", ["name"]);

=head1 RELATIONS

=head2 source_group

Type: belongs_to

Related object: L<Bio::EnsEMBL::Versioning::ORM::Schema::Result::SourceGroup>

=cut

__PACKAGE__->belongs_to(
  'source_groups',
  "Bio::EnsEMBL::Versioning::ORM::Schema::Result::SourceGroup",
  'source_group_id',
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 version

Type: has_many

Related object: L<Bio::EnsEMBL::Versioning::ORM::Schema::Result::Version>

=cut

__PACKAGE__->has_many(
  "versions",
  "Bio::EnsEMBL::Versioning::ORM::Schema::Result::Version",
  { "foreign.source_id" => "self.source_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "current_version",
  "Bio::EnsEMBL::Versioning::ORM::Schema::Result::Version",
  { "foreign.version_id" => "self.current_version"}
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-19 11:36:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:liBzUdy+yZqxkpR2MwONpA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;