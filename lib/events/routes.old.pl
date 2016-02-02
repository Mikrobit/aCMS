use events::Event;

prefix '/admin/events' => sub {

    # Show the form
    #
    get qr{/(edit)/(\d+)|/(new)} => sub {
        my ($action, $id) = splat;
        $id or $id = 0;
        my $post;
        
        if($action eq 'edit' && $id) {
            $post = Event::list($id);
        }

        template 'admin/events/edit' => { post => $post, action => $action };
    };
    # Handle it
    post qr{/(edit)/(\d+)|/(new)} => sub {
        my ($action, $id) = splat;
        my $post;
        # TODO Do someting with this in the view...
        my @err = [];

        # Mandatory fields
        $post->{'title'} = params->{"title"} || push @err, 'title';
        $post->{'content'} = params->{"content"} || push @err, 'content';
        $post->{'startDate'} = params->{"startDate"} || push @err, 'startDate';
        $post->{'hour'} = params->{"hour"} || push @err, 'hour';
        $post->{'minute'} = params->{"minute"} || push @err, 'minute';
        $post->{'duration'} = params->{"duration"} || push @err, 'duration';
        $post->{'durationUnit'} = params->{"durationUnit"} || push @err, 'durationUnit';
        # Check if all required fields were filled
        if($#err > 0) {
            template 'admin/events/edit' => { post => params, action => $action };
        }
        
        # Only set if editing existing post
        $post->{'id'} = $id || 0;
        
        # Optional fields
        $post->{'excerpt'} = params->{"excerpt"} || substr($post->{'content'}, 0, 100);
        $post->{'tags'} = params->{"tags"} || "";
        $post->{'status'} = params->{"status"} || "q";
        $post->{'type'} = params->{"type"} || "event";
        $post->{'dow'} = params->{"repeat['dow']"} || [];
        $post->{'dom'} = params->{"repeat['dom']"} || [];
        $post->{'endDate'} = params->{"endDate"} || "";

        my $msg;
        if (Event::save($action,$post)) {
            $msg = "Evento inserito correttamente";
        } else {
            $msg = "Errore inserendo l'evento";
        }
        redirect "/admin/events/list";
    };

    get '/list' => sub {
        $posts = Event::list_all();
        template 'admin/events/list' => { posts => $posts, status => 'p' };
    };

    get '/queue' => sub {
        $posts = Event::list_all();
        template 'admin/events/list' => { posts => $posts, status => 'q' };
    };

    get '/future' => sub {
        $posts = Event::list_future();
        template 'admin/events/list' => { posts => $posts };
    };

    get '/past' => sub {
        $posts = Event::list_past();
        template 'admin/events/list' => { posts => $posts };
    };

    get '/del/:id' => sub {
        if(Event::remove(param('id'))) { redirect '/admin/events/list'; }
        else {
            my $posts = Event::list_all();
            template 'admin/events/list' => { posts => $posts, status => 'p' };
        }
    };

};
