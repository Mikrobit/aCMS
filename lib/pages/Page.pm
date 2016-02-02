package Page;

use Dancer qw(:moose);
use Dancer::Plugin::Database qw(database);

use Moose;
use namespace::autoclean;

###########################################################
# Attributes and builders

has 'id'            => ( is => 'rw', isa => 'Int', default => 0 );
has 'title'         => ( is => 'rw', isa => 'Str', default => '' );
has 'content'       => ( is => 'rw', isa => 'Str', default => '');
has 'excerpt'       => ( is => 'rw', isa => 'Str', lazy => 1, default => '' );
has 'status'        => ( is => 'rw', isa => 'Str', lazy => 1, default => 'p' );
has 'parent'        => ( is => 'rw', isa => 'Int', lazy => 1, default => 0 );
has 'type'          => ( is => 'rw', isa => 'Str', lazy => 1, default => 'page' );
has 'tags'          => ( is => 'rw', isa => 'Str', lazy => 1, default => '' );
has 'site'          => ( is => 'rw', isa => 'Int', lazy => 1, builder => '_site' );
has 'slug'          => ( is => 'rw', isa => 'Str', lazy => 1, builder => '_slug' );

sub nicename {
    my $self = shift;
    my $user = Dancer::Plugin::Database::database->quick_lookup('users', { id => $self->author }, 'nicename');

    return $user;
}
sub author {
    my $self = shift;
    my $user;

    if ( $self->{'id'} ) { $user = Dancer::Plugin::Database::database->quick_lookup('posts', { id => $self->{'id'} }, 'author'); }
    else { $user = session->{'uid'} }

    return $user;
}
sub children {
    my $self = shift;
    my @children = Dancer::Plugin::Database::database->quick_select('posts', { parent => $self->{'id'} }, { columns => [qw(id title)] });

    return @children;
}

sub _site {
    my $site = Dancer::session('site') // Dancer::Plugin::Database::database->quick_lookup('sites', { domain => Dancer::request->host }, 'id');

    return $site;
}

sub _slug {
    my $self = shift;
    my $title = $self->title;

    $title =~ s/\s/_/g;
    $title =~ s/\W//g;
    $title =~ s/_/-/g;

    return lc $title;
}

########################################################
# Instance methods

sub fetch {
    my ($self, $field, $value) = @_;
    my $post = Dancer::Plugin::Database::database->quick_select('posts', { $field => $value } ) or return 0;

    $self->_db_to_obj($post);

    return 1;
}

# TODO: Cheddevofa? guarda 'children' sopra...
sub fetchChildren {
    my $self = shift;
    my @rows = Dancer::Plugin::Database::database->quick_select('posts', { parent => $self->{'id'} } ) or return 0;
    my @children;
    
    for my $child (@rows) {
        push @children, $self->_db_to_obj($child);
    }

    return \@children;
}

sub save {
    my ($self,$id) = @_;
    my $page = $self->_obj_to_db();

    if ($id) {
        $page->{'id'} = $id;
        return Dancer::Plugin::Database::database->quick_update('posts', { id => $id }, $page);
    } else {
        delete $page->{'id'};
        return Dancer::Plugin::Database::database->quick_insert('posts', $page);
    }
}

sub delete {
    my $self = shift;

    return Dancer::Plugin::Database::database->quick_delete('posts', { id => $self->id });
}

########################################################
# Class methods

sub list {
    my ($class, $parent) = @_;
    my @records;
    my @pages;

    $parent = 0 unless $parent;
    @records = Dancer::Plugin::Database::database->quick_select('posts',
        { site => $class->_site, type => 'page', status => 'p', parent => $parent },
        { columns => [qw(id title status parent)] });

    for my $page (@records) {
        push @pages, $class->new($page);
    }

    return \@pages;
}

sub showLatest {
    my ($class, $parent) = @_;
    my @records;
    my @pages;

    $parent = 0 unless $parent;
    @records = Dancer::Plugin::Database::database->quick_select('posts',
        { site => $class->_site, type => 'page', status => 'p', parent => $parent });

    for my $page (@records) {
        push @pages, $class->new($page);
    }

    return \@pages;
}

#########################################################
# Utilities

sub _obj_to_db {
    my $self = shift;
    my $hash = {};
    my @fields = qw(id author title content excerpt status parent type tags site slug status) ;

    for my $field (@fields) {
        $hash->{$field} = $self->$field;
    }

    return $hash;
}

sub _db_to_obj {
    my $self = shift;
    my $hash = shift;
    my @fields = qw(id author title content excerpt status parent type tags site slug status);

    for my $field (@fields) {
        $self->$field($hash->{$field});
    }

    return 1;
}

1;
