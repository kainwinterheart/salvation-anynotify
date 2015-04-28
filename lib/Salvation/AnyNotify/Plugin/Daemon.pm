package Salvation::AnyNotify::Plugin::Daemon;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Plugin';

use Salvation::DaemonDecl;
use Salvation::Method::Signatures;
use Salvation::DaemonDecl::Backend ();

method start() {

    $self -> { 'queue' } = [];
}

method enqueue( CodeRef|Str code ) {

    push( @{ $self -> { 'queue' } }, $code );

    return;
}

method run() {

    my $core = $self -> core();
    my $daemondecl_meta = $core -> daemondecl_meta();

    Salvation::DaemonDecl::Backend -> worker( $daemondecl_meta, {
        name 'main',
        max_instances 1,
        log {
            warn @_;
        },
        main {
            my ( $worker ) = @_;

            while( defined( my $code = shift( @{ $self -> { 'queue' } } ) ) ) {

                $core -> $code();
            }

            Salvation::DaemonDecl::Backend -> wait_all_workers( $daemondecl_meta );
        },
    } );

    Salvation::DaemonDecl::Backend -> daemon_main( $daemondecl_meta, 'main' );
}

1;

__END__
