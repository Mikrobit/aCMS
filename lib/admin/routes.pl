prefix '/admin' => sub {

    get '/' => sub {
        template 'admin/index';
    };

    get '/sites/:id' => sub {
        session site => param('id');
        redirect '/admin';
    };

};

1;
