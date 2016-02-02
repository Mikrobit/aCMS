use aCMS;

use Dancer;
use Dancer::Plugin::Database qw(database);

package News;

=item new()
Constructor for a News object
=cut
sub new {
    my ($class, $post) = @_;

    my $id = $post->{'id'};# // undef;
    my $author = $post->{'author'} // Dancer::session->{'uid'}; 
    my $title = $post->{'title'};# // "";
    my $slug = $post->{'slug'};# // undef;
    my $excerpt = $post->{'excerpt'} // $post->{'title'};
    my $content = $post->{'content'};# // "";
    my $tags = $post->{'tags'};# // "";
    my $type = $post->{'type'} // "post";
    my $status = $post->{'status'} // "q";
    my $site = $post->{'site'} // Dancer::session('site');
    my $modified = "now()";
    my $year = $post->{'year'};
    my $month = $post->{'month'};
    my $day = $post->{'day'};

    my $nicename = $post->{'nicename'};# // "";

    my $self = {
        # I don't need cleaning, dancer does it for me.
                author => $author,
                title => $title,
                excerpt => $excerpt,
                content => $content,
                tags => $tags,
                type => $type,
                status => $status,
                site => $site,
                modified => $modified,
                year => $year,
                month => $month,
                day => $day,
    };

    if (defined $slug) { $self->{'slug'} = $slug; } else { $self->{'slug'} = $class->_mkSlug($title); }
    if (defined $id) { $self->{'id'} = $id; }
    if ($nicename) { $self->{'nicename'} = $nicename; }

    push @{$self->{'comments'}}, Dancer::Plugin::Database::database->quick_select('comments', { post => $self->{'id'} }, { order_by => 'id' });

    $self->{'content'} = $class->_videofy($content);

    return bless($self, $class);
}

sub _videofy {
    my ($class, $content) = @_;
    # TODO Use regexp magic to replace youtube, vimeo links to corresponding embedding codes.
    return $content;
}

sub _mkSlug {
    my ($class, $title) = @_;
    my $i = 0;
    $title =~ s/\s/_/g;
    $title =~ s/\W//g;
    $title =~ s/_/-/g;
    return lc $title; 
}

sub _getHash {
    my $self = shift;
    my $hash = {
            id => $self->{'id'},
            author => $self->{'author'},
            title => $self->{'title'},
            slug => $self->{'slug'},
            excerpt => $self->{'excerpt'},
            content => $self->{'content'},
            tags => $self->{'tags'},
            type => $self->{'type'},
            status => $self->{'status'},
            site => $self->{'site'},
            modified => $self->{'modified'},
#            year => $self->{'year'},
#            month => $self->{'month'},
#            day => $self->{'day'},
    };
    return $hash;
}

=item get($id)
Get the contents of the News object $id, eventually modified with $updatedPost
Returns the object
=cut
sub get {
    my ($class, $id, $updatedPost) = @_;

    my $post = Dancer::Plugin::Database::database->quick_select('posts', { id => $id });
    if ($updatedPost) {
        @{$post}{keys %$updatedPost} = values %$updatedPost;
    }
    return $class->new($post);
};

sub getBySlug {
    my ($class, $slug) = @_;

    my $post = Dancer::Plugin::Database::database->quick_select('posts', { slug => $slug });
    return 0 unless ($post);
    return $class->new($post);
}

# getBySlugAndDate(lc params->{'slug'}, params->{'year'}, params->{'month'}, params->{'day'})
sub getBySlugAndDate {
    my ($class, $slug, $year, $month, $day) = @_;

    my $post = Dancer::Plugin::Database::database->quick_select('blogposts', { slug => $slug, year => $year, month => $month, day => $day });
    return 0 unless ($post);
    return $class->new($post);
}

=item latest()
Return latest $n News objects
=cut
sub latest {
    my ($class, $n) = @_;

    $n = 500 unless $n;

    my @posts = Dancer::Plugin::Database::database->quick_select('posts',
        { site => Dancer::session('site'), type => 'post' },
        { columns => ['id', 'title', 'status'], order_by => { desc => 'date' }, limit => $n }
    );
    my @news = [];
    foreach my $post (@posts) {
        push @news, $class->new($post);
    }
    return \@news;
};

=item showLatest()
Return latest $n Published complete news objects
=cut
sub showLatest {
    my ($class, $site, $n) = @_;

    $n = 500 unless $n;

    my $sth = Dancer::Plugin::Database::database->prepare('select * from blogpostltd(?,?)');
    $sth->execute($site,$n);

    my @posts;

    while (my $ref = $sth->fetchrow_hashref()) {
        push @posts, $ref;
    }
    my @news = [];
    foreach my $post (@posts) {
        push @news, $class->new($post);
    }
    return \@news;
}

sub getEntries {
    my ($class, $site, $hostname, $n) = @_;

    $n = 500 unless $n;

    my $sth = Dancer::Plugin::Database::database->prepare('select * from blogpostltd(?,?)');
    $sth->execute($site,$n);

    my @posts;

    while (my $ref = $sth->fetchrow_hashref()) {
        push @posts, {
            title       => $ref->{'title'},
            content     => $ref->{'content'},
            author      => $ref->{'nicename'},
            link        => 'http://' . $hostname . "/news/" . $ref->{'year'} . "/" . $ref->{'month'} . "/" . $ref->{'day'} . "/" . $ref->{'slug'},
        };  
    }

    return \@posts;
}

=item remove($id)
Remove News object identified by $id
=cut
sub remove {
    my ($class, $id) = @_;

    return Dancer::Plugin::Database::database->quick_delete('posts', { id => $id }) or return 0;
};

=head1 INSTANCE METHODS
=cut

=item save(action,$news)
Save the $news object to db.
action is new or update
=cut
sub save {
    my ($self,$action) = @_;
    my $db;

    if($action eq 'new') {
        my $post = $self->_getHash();
        delete $post->{'id'};
        $db = Dancer::Plugin::Database::database->quick_insert('posts', $post);
    } else {
        $db = Dancer::Plugin::Database::database->quick_update('posts', {id => $self->{'id'}}, $self->_getHash());
    }
    
    return $db;
};

1;
