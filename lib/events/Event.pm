package Event;

use Dancer qw(:moose);
use Dancer::Plugin::Database qw(database);

use DateTime;
use DateTime::Format::Pg;

use Moose;
use namespace::autoclean;

# Arguments to constructor or valid defaults:
has 'id'            => ( is => 'rw', isa => 'Int', default => 0 );
has 'modified'      => ( is => 'rw', isa => 'Str', default => 'now()' );
has 'excerpt'       => ( is => 'rw', isa => 'Str', lazy => 1, default => '' );
has 'content'       => ( is => 'rw', isa => 'Str', lazy => 1, default => '' );
has 'tags'          => ( is => 'rw', isa => 'Str', lazy => 1, default => '' );
has 'type'          => ( is => 'rw', isa => 'Str', lazy => 1, default => 'event' );
has 'status'        => ( is => 'rw', isa => 'Str', lazy => 1, default => 'p' );
has 'dow'           => ( is => 'rw', default => sub { [] } );
has 'dom'           => ( is => 'rw', default => sub { [] } );
# Required for builders (not lazy)
has 'title'         => ( is => 'rw', isa => 'Str', default => '' );
has 'startDate'     => ( is => 'rw', isa => 'Str', default => '' );
has 'hour'          => ( is => 'rw', isa => 'Int', default => 0 );
has 'minute'        => ( is => 'rw', isa => 'Int', default => 0 );
has 'endDate'       => ( is => 'rw', isa => 'Str', default => '' );
has 'durationValue' => ( is => 'rw', isa => 'Int', default => 0 );
has 'durationUnit'  => ( is => 'rw', isa => 'Str', default => 'm' );
# Need builders
#has 'author'        => ( is => 'rw', isa => 'Int', builder => '_uid' );
has 'site'          => ( is => 'rw', isa => 'Int', lazy => 1, builder => '_site' );
#has 'nicename'      => ( is => 'rw', isa => 'Str', lazy => 1, builder => '_name' );
has 'slug'          => ( is => 'rw', isa => 'Str', lazy => 1, builder => '_slug' );
has 'start'         => ( is => 'rw', lazy => 1, builder => '_start' );
has 'duration'      => ( is => 'rw', isa => 'Int', lazy => 1, builder => '_duration' );
has 'end'           => ( is => 'rw', lazy => 1, builder => '_end' );

sub nicename {
    my $self = shift;
    my $user = Dancer::Plugin::Database::database->quick_lookup('users', { id => $self->author }, 'nicename');
    return $user;
}

sub author {
    my $self = shift;
    my $user = Dancer::Plugin::Database::database->quick_lookup('posts', { id => $self->{'id'} }, 'author');
    return $user;
}

##### Instance methods (CRUD) #####

sub fetch {
    my ($self, $field, $value) = @_;

    my $post = Dancer::Plugin::Database::database->quick_select('posts',
        { $field => $value }
    ) or return 0;

    $self->_db_to_obj($post);

    my $start = DateTime::Format::Pg->parse_timestamptz($post->{'start'});
    my $end = DateTime::Format::Pg->parse_timestamptz($post->{'end'});

    $self->startDate($start->ymd);
    $self->hour($start->hour);
    $self->minute($start->minute);
    $self->endDate($end->ymd);

    return 1;
};

sub save {
    my ($self,$id) = @_;

    if ($id) {
        $self->{'id'} = $id;
        return Dancer::Plugin::Database::database->quick_update('posts',
            {id => $id }, $self->_obj_to_db()
        );
    } else {
        return Dancer::Plugin::Database::database->quick_insert('posts', $self->_obj_to_db());
    }
};
#D [deletes the current object from db]
sub delete {
    my $self = shift;

    return Dancer::Plugin::Database::database->quick_delete('posts', { id => $self->id });
};

##### Class methods ###### 

=item latest()
Return latest $n Event objects
=cut
sub latest {
    my ($class, $n) = @_;

    $n = 512 unless $n;

    my @posts = Dancer::Plugin::Database::database->quick_select('posts',
        { site => '1', type => 'event' }, #TODO site => '1' really??? ###FIXME###
        { columns => ['id', 'title', 'status'], order_by => { desc => 'date' }, limit => $n }
    );
    
    my @news;
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

    $n = 512 unless $n;

    my $now = DateTime::Format::Pg->format_timestamp_with_time_zone(DateTime->now(time_zone => 'Europe/Rome'));

    my @posts = Dancer::Plugin::Database::database->quick_select('posts',
        { site => '1', type => 'event', status => 'p',
            start => { 'le' => $now },# duration => { 'ge' => $now->add(minutes => $self->duration) }
        },
        { columns => ['id', 'title', 'status', 'content'], order_by => { desc => 'end' }, limit => $n }
    );
    
    my @news;
    foreach my $post (@posts) {
        push @news, $class->new($post);
    }
    return \@news;
};

###### /Class methods #####

sub _obj_to_db {
    ### TODO ### Validation check + handle exceptions?
    my $self = shift;
    my $hash = {};

    my @fields = qw(id author title content excerpt status modified type tags site start duration end slug status) ;
    for my $field (@fields) {
        $hash->{$field} = $self->$field;
    }
    $hash->{dow} = $self->dow();
    $hash->{dom} = $self->dom();

    return $hash;
};

sub _db_to_obj {
    my $self = shift;
    my $hash = shift;

    my @fields = qw(id author title content excerpt status modified type tags site start duration end slug dow dom status) ;

    for my $field (@fields) {
        $self->$field($hash->{$field});
    }
    return 1;
};

######################## BUILDERS ##########################
# builder for start attribute
sub _start {
    my $self = shift;

    my ($Y, $M, $D) = split('\-', $self->startDate);
    my $start = DateTime->new(
        year        => $Y,
        month       => $M,
        day         => $D,
        hour        => $self->hour,
        minute      => $self->minute,
        time_zone   => 'Europe/Rome', #TODO ugly hardcoded timezone, make it configurable
    );

    return DateTime::Format::Pg->format_timestamp_with_time_zone($start);
}

# builder for duration attribute
sub _duration {
    my $self = shift;
    
    my $durationMin = $self->durationValue;

    # Let's convert duration to minutes
    if ($self->durationUnit eq 'h') { $durationMin = $self->durationValue * 60; }
    elsif ($self->durationUnit eq 'd') { $durationMin = $self->durationValue * 60 * 24; }

    return $durationMin;
}

# builder for end attribute
sub _end {
    my $self = shift;

    my $end;
    if ($self->endDate ne "") {
        my ($endY, $endM, $endD) = split('\-', $self->endDate);
        $end = DateTime->new(
            year        => $endY,
            month       => $endM,
            day         => $endD,
            time_zone   => 'Europe/Rome', #TODO ugly hardcoded timezone, make it configurable
        );
        $end->add(minutes => $self->duration);
    }
    return DateTime::Format::Pg->format_timestamp_with_time_zone($end);
}

# builder for slug attribute
sub _slug {
    my $self = shift;

    my $title = $self->title;
    $title =~ s/\s/_/g;
    $title =~ s/\W//g;
    $title =~ s/_/-/g;
    return lc $title;
}

sub _site {
    my $self = shift;

    my $sites = Dancer::session('sites');
    foreach my $site (keys $sites) {
        if ( $sites->{$site}->{'domain'} eq Dancer::request->host ) {
            return $sites->{$site}->{'id'};
        }
    }
    return 1;
}

######################## /BUILDERS #########################

1;
