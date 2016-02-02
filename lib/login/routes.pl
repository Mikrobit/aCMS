use Dancer::Plugin::Database;
use Digest::SHA qw(sha1_hex);

use login::Login;

# Login
hook 'before' => sub {
    if (request->path_info =~ m{^/admin}) {
        if (!session('user') && request->path_info !~ m{^/login}) {
            var requested_path => request->path_info;
            request->path_info('/login');
        }
    }
};
  
get '/login' => sub {
    template 'login', { path => vars->{requested_path}, failed => params->{failed} };
};

post '/login' => sub {

    redirect '/login?failed=1' unless (params->{user} and params->{pass});
    my $user = aCMS::v_i(params->{user});
    my $pass = sha1_hex(aCMS::v_i(params->{pass}));
    # TODO: Usa database->quick_select
    my $sth = database->prepare("SELECT * FROM users WHERE \"login\" = ? AND pass = ? AND status = 'a';");
    $sth->execute($user,$pass);
    my $u = $sth->fetchrow_hashref;

    if ($u) {
        session uid => aCMS::v_o($u->{id});
        session user => aCMS::v_o($u->{login});
        session email => aCMS::v_o($u->{email});
        session nicename => aCMS::v_o($u->{nicename});
        session type => aCMS::v_o($u->{type});

        session sites => Login::get_sites($u->{id});

        redirect params->{path} || '/admin';
    } else {
        redirect '/login?failed=1';
    }
};

get '/logout' => sub {
    session->destroy;
    redirect params->{path} || '/login';
};

1;
