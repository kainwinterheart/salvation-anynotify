package Salvation::AnyNotify::Plugin::Bus;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Plugin';

use Salvation::Method::Signatures;
use Salvation::DaemonDecl::Backend ();

method notify( Str{1,} channel, Str{1,} data ) {

    my $core = $self -> core();

    Salvation::DaemonDecl::Backend -> write_to(
        $core -> daemondecl_meta(),
        $core -> server() -> pid(),
        pack( 'N', length( $channel ) )
        . $channel
        . pack( 'N', length( $data ) )
        . $data
    );

    return;
}

1;

__END__
