use aCMS;

use Dancer;
use Dancer::Plugin::Feed;

use news::News;

prefix '/admin/news' => sub {
    
    my $post = {};
    my $posts;

    # Show the form
    #
    get qr{/(edit)/(\d+)|/(new)} => sub {
        my ($action, $id) = splat;


        if($action eq 'edit' && $id) {
            $post = News->get($id,{});
        } else {
            $post = {};
        }

        template 'admin/news/edit' => { post => $post, action => $action };
    };
    # Handle it
    post qr{/(edit)/(\d+)|/(new)} => sub {
        my ($action, $id) = splat;
        my $par = params;
        $id or $id = 0;

        if($action eq 'edit' && $id) {
            $post = News->get($id,$par);
        } else {
            $post = News->new($par);
        }

        if ($post->{'title'} && $post->{'content'}) {
            $post->save($action);
            redirect "/admin/news/list";
        }
        else {
            $posts = News->latest(100);
            template 'admin/news/list' => { posts => $posts, status => 'p' };
        }
    };

    get '/list' => sub {
        $posts = News->latest(100);
        template 'admin/news/list' => { posts => $posts, status => 'p' };
    };

    get '/queue' => sub {
        $posts = News->latest(100);
        template 'admin/news/list' => { posts => $posts, status => 'q' };
    };

    get '/waiting' => sub {
        $posts = News->latest(100);
        template 'admin/news/list' => { posts => $posts, status => 'w' };
    };

    get '/del/:id' => sub {
        if(News->remove(param('id'))) { redirect '/admin/news/list'; }
        else {
            my $posts = News->latest(100);
            template 'admin/news/list' => { posts => $posts, status => 'p' };
        }
    };

};

prefix '/news' => sub {

    get '/' => sub {
        
        my $site = Dancer::Plugin::Database::database->quick_select('sites', { domain => request->{'host'} });
        if ( my $posts = News->showLatest( $site->{'id'},100 ) ) {
            return template 'news/list' => { posts => $posts, site => $site, comments => 0 };
        }
        status "Not found";
        redirect "/";
    };

    get '/:year/:month/:day/:slug' => sub {

        my $site = Dancer::Plugin::Database::database->quick_select('sites', { domain => request->{'host'} });
        if (my $post = News->getBySlugAndDate(lc params->{'slug'}, params->{'year'}, params->{'month'}, params->{'day'})) {
            $post->{'nicename'} = Dancer::Plugin::Database::database->quick_lookup('users', { id => $post->{'author'} }, 'nicename');
            return template 'news/article' => { post => $post, site => $site, comments => 1 };
        }
        status "Not found";
        redirect '/';
    };

    # Feed!

    get '/feed/:format' => sub {

        use Data::Dumper::HTML qw(dumper_html);
        my $site = Dancer::Plugin::Database::database->quick_select('sites', { domain => request->{'host'} });
        my $entries = News->getEntries( $site->{'id'}, $site->{'domain'}, 100 );
        my $feed = create_feed( 
            format => params->{'format'}, #Feed format (RSS or Atom) 
            title => $site->{'title'}, 
            entries => $entries ,
        );

        return $feed;
    
    };

};
