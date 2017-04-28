package MT::ContentFieldType::Asset;
use strict;
use warnings;

use MT;
use MT::Asset;
use MT::Author;
use MT::ContentFieldType::Common
    qw( get_cd_ids_by_inner_join get_cd_ids_by_left_join );
use MT::ObjectTag;
use MT::Tag;

sub field_html {
    my ( $app, $field_id, $value ) = @_;
    $value = ''       unless defined $value;
    $value = [$value] unless ref $value eq 'ARRAY';

    my $html
        = '<input type="text" name="content-field-'
        . $field_id
        . '" class="text long" value="';
    $html .= join ',', @$value;
    $html .= '" />';
    return $html;
}

sub data_getter {
    my ( $app, $id ) = @_;
    my $asset_ids = $app->param( 'content-field-' . $id );
    my @asset_ids = split ',', $asset_ids;

    my %valid_assets
        = map { $_->id => 1 } MT::Asset->load( { id => \@asset_ids },
        { no_class => 1, fetchonly => { id => 1 } } );

    [ grep { $valid_assets{$_} } @asset_ids ];
}

sub single_select_options {
    my $prop = shift;
    my $app = shift || MT->app;

    my @assets = MT::Asset->load( { blog_id => $app->blog->id },
        { fetchonly => { id => 1, label => 1 }, no_class => 1 } );

    my @options;
    for my $asset (@assets) {
        my $label = $asset->label . ' (id:' . $asset->id . ')';
        push @options,
            {
            label => $label,
            value => $asset->id,
            };
    }
    \@options;
}

sub terms_author_name {
    my $prop = shift;
    my ( $args, $load_terms, $load_args ) = @_;

    my $col = 'created_by';
    my $prop_super = MT->registry( 'list_properties', '__virtual', 'string' );

    my ( $name_query, $nick_query );
    {
        local $prop->{col} = 'name';
        $name_query = $prop_super->{terms}->( $prop, @_ );
    }
    {
        local $prop->{col} = 'nickname';
        $nick_query = $prop_super->{terms}->( $prop, @_ );
    }

    my $option = $args->{option} || '';
    if ( $option eq 'not_contains' ) {
        my $string       = $args->{string};
        my $author_terms = [
            { name => { like => "%${string}%" } },
            '-or',
            { nickname => { like => "%${string}%" } },
        ];
        my $author_join = MT::Author->join_on( undef,
            [ $author_terms, { id => \'= asset_created_by' } ] );
        my @asset_ids = map { $_->id } MT::Asset->load(
            undef,
            {   no_class => 1,
                join     => $author_join,
            },
        );
        my $join_terms = { value_integer => [ \'IS NULL', @asset_ids ] };
        my $cd_ids = get_cd_ids_by_left_join( $prop, $join_terms, undef, @_ );
        $cd_ids ? { id => { not => $cd_ids } } : ();
    }
    else {
        my $author_terms = [ $name_query, $nick_query ];
        my $author_join
            = MT::Author->join_on( undef,
            [ { id => \'= asset_created_by' }, $author_terms ] );
        my $asset_join = MT::Asset->join_on(
            undef,
            { id => \'= cf_idx_value_integer' },
            {   no_class => 1,
                join     => $author_join,
            }
        );
        my $join_args = { join => $asset_join };
        my $cd_ids = get_cd_ids_by_inner_join( $prop, undef, $join_args, @_ );
        { id => $cd_ids };
    }
}

sub terms_author_status {
    my $prop = shift;
    my ( $args, $db_terms, $db_args ) = @_;

    my $status_query = $prop->super(@_);
    my $author_join
        = MT::Author->join_on( undef,
        [ { id => \'= asset_created_by' }, $status_query ] );
    my $asset_join = MT::Asset->join_on(
        undef,
        { id => \'= cf_idx_value_integer' },
        {   no_class => 1,
            join     => $author_join,
        }
    );
    my $join_args = { join => $asset_join };
    my $cd_ids = get_cd_ids_by_inner_join( $prop, undef, $join_args, @_ );
    { id => $cd_ids };
}

sub terms_date {
    my $prop = shift;
    my ( $args, $db_terms, $db_args ) = @_;

    my $query = $prop->super(@_);

    my $asset_join = MT::Asset->join_on(
        undef,
        [ { id => \'= cf_idx_value_integer' }, $query ],
        { no_class => 1 },
    );

    my $join_args = { join => $asset_join };
    my $cd_ids = get_cd_ids_by_inner_join( $prop, undef, $join_args, @_ );
    { id => $cd_ids };
}

sub terms_tag {
    my $prop = shift;
    my ( $args, $base_terms, $base_args, $opts ) = @_;

    my $query = $prop->super(@_);

    my $option = $args->{option};
    if ( 'not_contains' eq $option ) {
        my $string   = $args->{string};
        my $tag_join = MT::Tag->join_on(
            undef,
            {   name => { like => "%${string}%" },
                id   => \'= objecttag_tag_id'
            }
        );
        my @asset_ids = map { $_->object_id } MT::ObjectTag->load(
            {   blog_id           => MT->app->blog->id,
                object_datasource => 'asset',
            },
            {   join      => $tag_join,
                fetchonly => { object_id => 1 },
            },
        );
        my $join_terms = { value_integer => [ \'IS NULL', @asset_ids ] };
        my $cd_ids = get_cd_ids_by_left_join( $prop, $join_terms, undef, @_ );
        $cd_ids ? { id => { not => $cd_ids } } : ();
    }
    elsif ( 'blank' eq $option ) {
        my $objecttag_join = MT::ObjectTag->join_on(
            undef,
            { object_id => \'IS NULL' },
            {   type      => 'left',
                condition => {
                    object_datasource => 'asset',
                    object_id         => \'= cf_idx_value_integer',
                },
            },
        );
        my $join_args = { join => $objecttag_join };
        my $cd_ids = get_cd_ids_by_inner_join( $prop, undef, $join_args, @_ );
        { id => $cd_ids };
    }
    else {
        my $tag_join = MT::Tag->join_on( undef,
            [ { id => \'= objecttag_tag_id' }, $query ] );
        my $objecttag_join = MT::ObjectTag->join_on(
            undef,
            {   object_datasource => 'asset',
                object_id         => \'= cf_idx_value_integer',
            },
            { join => $tag_join },
        );
        my $join_args = { join => $objecttag_join };
        my $cd_ids = get_cd_ids_by_inner_join( $prop, undef, $join_args, @_ );
        if ( 'not_contains' eq $option ) {
            $cd_ids ? { id => { not => $cd_ids } } : ();
        }
        else {
            { id => $cd_ids };
        }
    }
}

sub terms_image_size {
    my $prop = shift;
    my ( $args, $db_terms, $db_args ) = @_;

    my $super = MT->registry( 'list_properties', '__virtual', 'integer' );
    my $super_terms = $super->{terms}->( $prop, @_ );

    my $option = $args->{option} || '';
    if ( $option eq 'not_equal' ) {
        my $value = $args->{value} || 0;
        my $asset_meta_join
            = MT::Asset->meta_pkg->join_on( 'asset_id',
            { type => $prop->meta_type, vinteger => $value },
            );
        my @asset_ids = map { $_->id } MT::Asset->load(
            { blog_id => MT->app->blog->id },
            {   no_class  => 1,
                join      => $asset_meta_join,
                fetchonly => { id => 1 },
            },
        );
        my $join_terms = { value_integer => [ \'IS NULL', @asset_ids ] };
        my $cd_ids = get_cd_ids_by_left_join( $prop, $join_terms, undef, @_ );
        $cd_ids ? { id => { not => $cd_ids } } : ();
    }
    else {
        my $asset_meta_join
            = MT::Asset->meta_pkg->join_on( 'asset_id',
            [ { type => $prop->meta_type }, $super_terms ],
            );
        my $asset_join = MT::Asset->join_on(
            undef,
            { id => \'= cf_idx_value_integer' },
            {   no_class => 1,
                join     => $asset_meta_join,
            },
        );
        my $join_args = { join => $asset_join };
        my $cd_ids = get_cd_ids_by_inner_join( $prop, undef, $join_args, @_ );
        { id => $cd_ids };
    }
}

sub terms_missing_file {
    my $prop = shift;
    my ( $args, $db_terms, $db_args ) = @_;

    require MT::FileMgr;
    my $fmgr = MT::FileMgr->new('Local');

    my $filter
        = $args->{value}
        ? sub { !$fmgr->exists( $_[0] ) }
        : sub { $fmgr->exists( $_[0] ) };

    my $iter = MT::Asset->load_iter(
        { blog_id => MT->app->blog->id },
        {   no_class => 1,
            join     => MT::ContentFieldIndex->join_on(
                undef,
                {   value_integer    => \'= asset_id',
                    content_field_id => $prop->content_field_id,
                },
            )
        }
    );

    my @asset_ids;
    while ( my $asset = $iter->() ) {
        push @asset_ids, $asset->id
            if defined $asset->file_path
            && $asset->file_path ne ''
            && $filter->( $asset->file_path );
    }

    return { id => 0 } unless @asset_ids;    # no data

    my $join_terms = { value_integer => \@asset_ids };
    my $cd_ids = get_cd_ids_by_inner_join( $prop, $join_terms, undef, @_ );
    { id => $cd_ids };
}

sub terms_text {
    my $prop = shift;
    my ( $args, $db_terms, $db_args ) = @_;

    my $option = $args->{option} || '';

    if ( $option eq 'not_contains' ) {
        my $col       = $prop->col;
        my $string    = $args->{string};
        my @asset_ids = map { $_->id } MT::Asset->load(
            {   blog_id => MT->app->blog->id,
                $col => { like => "%${string}%" },
            },
            { no_class => 1, fetchonly => { id => 1 } },
        );
        my $join_terms = { value_integer => [ \'IS NULL', @asset_ids ] };
        my $cd_ids = get_cd_ids_by_left_join( $prop, $join_terms, undef, @_ );
        $cd_ids ? { id => { not => $cd_ids } } : ();
    }
    else {
        my $query      = $prop->super(@_);
        my $asset_join = MT::Asset->join_on(
            undef,
            [ { id => \'= cf_idx_value_integer' }, $query ],
            { no_class => 1 },
        );
        my $join_args = { join => $asset_join };
        my $cd_ids = get_cd_ids_by_inner_join( $prop, undef, $join_args, @_ );
        { id => $cd_ids };
    }
}

sub terms_id {
    my $prop = shift;
    my ( $args, $db_terms, $db_args ) = @_;

    my $option = $args->{option} || '';

    if ( $option eq 'not_equal' ) {
        my $col        = $prop->col;
        my $value      = $args->{value} || 0;
        my $join_terms = { $col => [ \'IS NULL', $value ] };
        my $cd_ids = get_cd_ids_by_left_join( $prop, $join_terms, undef, @_ );
        $cd_ids ? { id => { not => $cd_ids } } : ();
    }
    else {
        my $join_terms = $prop->super(@_);
        my $cd_ids = get_cd_ids_by_left_join( $prop, $join_terms, undef, @_ );
        { id => $cd_ids };
    }
}

sub html {
    my $prop = shift;
    my ( $content_data, $app, $opts ) = @_;

    my $cd_id     = $content_data->id;
    my $field_id  = $prop->content_field_id;
    my $asset_ids = $content_data->data->{$field_id} || [];

    my %assets
        = map { $_->id => $_ }
        MT::Asset->load( { id => $asset_ids }, { no_class => 1 } );
    my @assets = map { $assets{$_} } @$asset_ids;

    my ( @ids, @thumbnails );
    for my $asset (@assets) {
        my $id             = $asset->id;
        my $thumbnail_html = _thumbnail_html( $app, $asset );
        my $edit_link      = _edit_link( $app, $asset );

        push @ids,        qq{<a href="${edit_link}">${id}</a>};
        push @thumbnails, qq{<a href="${edit_link}">${thumbnail_html}</a>};
    }

    my $ids_html
        = qq{<span id="asset-ids-${cd_id}-${field_id}" class="id">}
        . join( ', ', @ids )
        . '</span>';
    my $thumbnails_html
        = qq{<span id="asset-thumbnails-${cd_id}-${field_id}" class="thumbnail">}
        . join( '', @thumbnails )
        . '</span>';
    my $js = <<"__JS__";
<script>
jQuery(document).ready(function() {
  jQuery("#custom-prefs-content_field_${field_id}\\\\.thumbnail").change(function() {
    changeIds();
  });

  function changeIds() {
    if (jQuery("#custom-prefs-content_field_${field_id}\\\\.thumbnail").prop('checked')) {
      jQuery('#asset-ids-${cd_id}-${field_id}').css('display', 'none');
    } else {
      jQuery('#asset-ids-${cd_id}-${field_id}').css('display', 'inline');
    }
  }

  changeIds();
});
</script>
__JS__

    $ids_html . $thumbnails_html . $js;
}

sub _edit_link {
    my ( $app, $asset ) = @_;
    $app->uri(
        mode => 'edit',
        args => {
            _type   => 'asset',
            blog_id => $asset->blog_id,
            id      => $asset->id,
        },
    );
}

sub _thumbnail_html {
    my ( $app, $asset ) = @_;

    my $edit_link  = _edit_link( $app, $asset );
    my $thumb_size = 45;
    my $class_type = $asset->class_type;
    my $file_path  = $asset->file_path;
    my $img
        = MT->static_path
        . 'images/asset/'
        . $class_type . '-'
        . $thumb_size . '.png';

    my ( $orig_width, $orig_height )
        = ( $asset->image_width, $asset->image_height );
    my ( $thumbnail_url, $thumbnail_width, $thumbnail_height );
    if (   $orig_width > $thumb_size
        && $orig_height > $thumb_size )
    {
        ( $thumbnail_url, $thumbnail_width, $thumbnail_height )
            = $asset->thumbnail_url(
            Height => $thumb_size,
            Width  => $thumb_size,
            Square => 1,
            Ts     => 1
            );
    }
    elsif ( $orig_width > $thumb_size ) {
        ( $thumbnail_url, $thumbnail_width, $thumbnail_height )
            = $asset->thumbnail_url(
            Width => $thumb_size,
            Ts    => 1
            );
    }
    elsif ( $orig_height > $thumb_size ) {
        ( $thumbnail_url, $thumbnail_width, $thumbnail_height )
            = $asset->thumbnail_url(
            Height => $thumb_size,
            Ts     => 1
            );
    }
    else {
        ( $thumbnail_url, $thumbnail_width, $thumbnail_height ) = (
            $asset->url . '?ts=' . $asset->modified_on,
            $orig_width, $orig_height
        );
    }

    my $thumbnail_width_offset
        = int( ( $thumb_size - $thumbnail_width ) / 2 );
    my $thumbnail_height_offset
        = int( ( $thumb_size - $thumbnail_height ) / 2 );

    qq{<img alt="" src="${thumbnail_url}" style="padding: ${thumbnail_height_offset}px ${thumbnail_width_offset}px" />};
}

1;

