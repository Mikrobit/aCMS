use Dancer;

use events::Event;

prefix '/admin/events' => sub {

    # Show the form
    #
    get qr{/(edit)/(\d+)|/(new)} => sub {
        my ($action, $id) = splat;

        my $post = Event->new();

        if($action eq 'edit' && $id) {
            $post->fetch('id', $id);
        }

        $post->durationValue($post->duration);
        unless ( $post->durationValue % 60 ) {
            $post->durationValue($post->durationValue/60);
            $post->durationUnit('h');
        }
        unless ( $post->durationValue % 24 ) {
            $post->durationValue($post->durationValue/24);
            $post->durationUnit('d');
        }

        template 'admin/events/edit' => { post => $post, action => $action };
    };
    # Handle it
    post qr{/(edit)/(\d+)|/(new)} => sub {
        my ($action, $id) = splat;

        my $post = Event->new(params);

        if ($action eq 'new') {
            $post->save();
        } else {
            $post->save($id);
        }

        redirect "/admin/events/list";
    };

    get '/list' => sub {

        my $posts = Event->latest();
        template 'admin/events/list' => { posts => $posts, status => 'p' };
    };

    get '/del/:id' => sub {

        my $post = Event->new({ id => param('id') });
        if($post->delete()) { redirect '/admin/events/list'; }
        else {
            my $posts = Event->latest();
            template 'admin/events/list' => { posts => $posts, status => 'p' };
        }
    };

};
prefix '/events' => sub {
    get '/' => sub {

        my $posts = Event->showLatest();
        template 'events/home' => { posts => $posts, status => 'p' };
    };
    get '/:id' => sub {
        
        my $post = Event->new();
        $post->fetch('id', param('id') );
    };
};


