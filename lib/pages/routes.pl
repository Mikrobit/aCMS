use Dancer;

use pages::Page;

prefix '/admin/pages' => sub {
    # Show the form for editing/creating a page
    get qr{/(edit)/(\d+)|/(new)} => sub {
        my ($action, $id) = splat;
        my $page = Page->new();
        my @children;

        if ( $action eq 'edit' && $id ) {
            $page->fetch('id', $id);
            @children = $page->fetchChildren();
        }

        return template 'admin/pages/edit' => { page => $page, action => $action, children => @children };
    };
    # Handle it.
    post qr{/(edit)/(\d+)|/(new)} => sub {
        my ($action, $id) = splat;
        my $page = Page->new(params);

        if ( $action eq 'new' ) { $page->save(); }
        else { $page->save($id); }

        return redirect '/admin/pages/list/';
    };

    # Show pages, optionally with :parent
    get '/list/:parent?' => sub {
        my $pages = Page->list(param('parent'));

        return template 'admin/pages/list' => { pages => $pages };
    };

    get '/del/:id' => sub {
        my $page = Page->new({ id => param 'id' });

        $page->delete();

        return redirect '/admin/pages/list/';
    };
};

prefix '/pages' => sub {
    get '/' => sub {
        my $pages = Page->showLatest();

        my $site = Dancer::Plugin::Database::database->quick_select('sites', { domain => request->{'host'} });

        return template 'pages/list' => { pages => $pages, status => 'p', site => $site };
    };
    get '/:page' => sub {
        my $page = Page->new();

        $page->fetch('slug', param('page'));

        return template 'pages/page' => { page => $page };
    };
};
