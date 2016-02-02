use Modern::Perl 2012;

package aCMS v2012.07.31;

use Dancer;
use Dancer::Plugin::Database;
require File::Basename;

# Anti-bobby tables validation
# 
sub v_i {
    my $input = shift;
    $input =~ s/(\W)/\\$1/g;
    return $input;
};

sub v_o {
    my $output = shift;
    $output =~ s/\\(\W)/$1/g;
    return $output;
};

# Main

get '/' => sub {
    my $site = Dancer::Plugin::Database::database->quick_select('sites', { domain => request->{host} });
    if ($site->{'home'} ne '/') {
        redirect $site->{'home'};
    } else {
        template 'index' => { appname => config->{appname}, url => request->{host} };
    }

};

# Reverse-engineering of nicEdit's image upload

post '/up' => sub {
    my $id = params->{'id'};
    my $file = upload('nicImage');

    my @validExtensions = ( '.jpg', '.gif', '.png', '.tiff', '.jpeg', '.bmp' );
    my $docroot = `pwd`;

    chomp($docroot);
    $file->filename =~ /(\.[^.]*)$/;
    my $ext = lc $1;
    return "Invalid file type" unless($ext ~~ @validExtensions);
    my $pathname = $docroot."/public/uploads/".$id.$ext;

    $file->copy_to($pathname);
    my ($base, $path) = File::Basename::fileparse($pathname,qr/\.[^.]*$/);
    use Carp;
    eval {
        `convert $pathname -resize 500x500 $path/$base.final$ext`;
        unlink $pathname;
    } || confess "$0: Caught exception: $@";

    my $final = '
    <html>
    <body>
        <div id="uploadingMessage" style="text-align: center; font-size: 14px;">
            <img src="/images/ajax-loader.gif" style="float: right; margin-right: 40px;" />
            <strong>Uploading...</strong><br />
            Please wait
        </div>
    </body>
    </html>
    ';

    return $final;
};

get '/up' => sub { # Check if id.anything exists
    my $check = params->{'check'};
    my $rand = params->{'rand'}; # ?

    my @validExtensions = ( '.jpg', '.gif', '.png', '.tiff', '.jpeg', '.bmp' );

    my $script;

    my $docroot = `pwd`;
    chomp($docroot);
    my $pathname = $docroot."/public/uploads/".$check.".final";

    for my $ext (@validExtensions) {
        if( -f $pathname.$ext ) {
            my $status = {
                done => 1,
                width => 500,
                url => "http://".request->host."/uploads/".$check.".final".$ext,
            };
            $script = '
                try {
                    nicUploadButton.statusCb('.to_json($status).');
                } catch(e) { alert(e.message); }
            ';
        }
    }

    return $script;
};

load 'login/routes.pl', 'admin/routes.pl', 'comments/routes.pl', 'news/routes.pl', 'pages/routes.pl' ;#, 'events/routes.pl';

1;
