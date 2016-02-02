use aCMS;

use Dancer;
use Dancer::Plugin::Database;

use HTML::Strip;

post '/comment' => sub {
    my $comment = {
        user => session('uid'),
        post => params->{'id'},
        title => params->{'title'},
        content => params->{'content'},
        author => params->{'author'},
        author_email => params->{'author_email'},
        author_url => params->{'author_url'},
        author_ip => request->remote_address,
        approved => config->{'auto-approve-comments'},
        parent => params->{'parent'},
    };

    my $hs = HTML::Strip->new();
    $comment->{'title'} = $hs->parse($comment->{'title'});
    $comment->{'content'} = $hs->parse($comment->{'content'});
    $comment->{'author'} = $hs->parse($comment->{'author'});
    $comment->{'author_email'} = $hs->parse($comment->{'author_email'});
    $comment->{'author_url'} = $hs->parse($comment->{'author_url'});
    $hs->eof;

#    use DDP; p $comment;

    Dancer::Plugin::Database::database->quick_insert('comments', $comment) if(params->{'captcha'} eq '24');
    
    return redirect request->referer;
};
