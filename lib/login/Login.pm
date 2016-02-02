package Login;

use Exporter 'import';
@ISA = qw(Exporter);
@EXPORT = qw(get_sites);

use aCMS;
use Dancer::Plugin::Database;
use Digest::SHA qw(sha1_hex);

sub get_sites {
    my $uid = shift;
    my ($site, $sites);
    my $query = "SELECT s.* FROM sites s LEFT JOIN sites_users su ON su.site = s.id WHERE su.user = ?;";
    my $sth = database->prepare($query);
    $sth->execute($uid) or debug $sth->errstr;
    # Hold on tight...
    while ($site = $sth->fetchrow_hashref()) {
        for my $column (keys %$site) {
            $sites->{$site->{id}}->{$column} = $site->{$column} ;
        }
    }
    return $sites;
};

1;
