package Salvation::AnyNotify::Plugin::Server;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Plugin';

use AnyEvent ();
use Salvation::TC ();
use Plack::Request ();
use Sub::Recursive 'recursive', '$REC';
use Twiggy::Server ();
use Salvation::DaemonDecl;
use Salvation::DaemonDecl::Backend ();
use Salvation::Method::Signatures;

sub default_message_ttl { 60 }

method pid() {

    return $self -> { 'pid' };
}

method serve_request(
    Salvation::DaemonDecl::Worker worker, Plack::Request request,
    HashRef channels
) {

    my $channel = ( $channels -> { $request -> parameters() -> get( 'channel' ) } // {} );
    my $now = time();
    my $ttl = $channel -> { 'ttl' };
    my $body = '';
    my @new_queue = ();
    my $response = $request -> new_response( 200 );

    while( defined( my $node = shift( @{ $channel -> { 'queue' } } ) ) ) {

        if( ( $node -> { 'time' } + $ttl ) > $now ) {

            push( @new_queue, $node );
        }

        $body .= pack( 'N', length( $node -> { 'data' } ) );
        $body .= $node -> { 'data' };
    }

    $response -> content_type( 'text/plain' );
    $response -> body( $body );

    return $response -> finalize();
}

method start() {

    my $core = $self -> core();
    my $config = $core -> config();
    my $host = $config -> get( 'server.host' ),
    my $port = $config -> get( 'server.port' ),
    my $default_message_ttl = (
        $config -> get( 'server.default_message_ttl' )
        // $self -> default_message_ttl(),
    );

    Salvation::TC -> assert(
        [ $host, $port, $default_message_ttl ],
        'ArrayRef( Str{1,} host, Int port, Int default_message_ttl )'
    );

    my $daemondecl_meta = $core -> daemondecl_meta();

    Salvation::DaemonDecl::Backend -> worker( $daemondecl_meta, {
        name 'http server',
        max_instances 1,
        log {
            warn @_;
        },
        main {
            my ( $worker ) = @_;
            my $server = Twiggy::Server -> new( host => $host, port => $port );
            my %channels = ();

            $server -> register_service( sub {

                return $self -> serve_request(
                    $worker,
                    Plack::Request -> new( @_ ),
                    \%channels,
                );
            } );

            my @stack = ();
            my $cb; push( @stack, recursive {

                my $cv = AnyEvent -> condvar();

                # read channel length
                my $read_cv = $worker -> read_from_parent( 4, sub {

                    my ( $len ) = @_;
                    $len = unpack( 'N', $len );

                    # read channel value
                    my $read_cv = $worker -> read_from_parent( $len, sub {

                        my ( $channel ) = @_;
                        my $ttl = ( $config -> get( sprintf(
                            'server.channel.%s.ttl',
                            $channel,
                        ) ) // $default_message_ttl );

                        $channels{ $channel } -> { 'ttl' } = $ttl;

                        # read data length
                        my $read_cv = $worker -> read_from_parent( 4, sub {

                            my ( $len ) = @_;
                            $len = unpack( 'N', $len );

                            # read data
                            my $read_cv = $worker -> read_from_parent( $len, sub {

                                my ( $data ) = @_;

                                push( @{ $channels{ $channel } -> { 'queue' } }, {
                                    data => $data,
                                    time => time(),
                                } );
                            } );

                            $read_cv -> cb( sub { $cv -> send( scalar $read_cv -> recv() ) } );
                        } );

                        $read_cv -> cb( sub {

                            if( my $rv = $read_cv -> recv() ) {

                                $cv -> send( $rv );
                            }
                        } );
                    } );

                    $read_cv -> cb( sub {

                        if( my $rv = $read_cv -> recv() ) {

                            $cv -> send( $rv );
                        }
                    } );
                } );

                $read_cv -> cb( sub {

                    if( my $rv = $read_cv -> recv() ) {

                        $cv -> send( $rv );
                    }
                } );

                wait_cond( $cv );

                if( scalar $cv -> recv() ) {

                    Salvation::DaemonDecl::Backend
                        -> wait_all_workers( $daemondecl_meta, 'frontend' );

                } else {

                    unless( defined $cb ) {

                        weaken( $cb = $REC );
                    }

                    push( @stack, $cb );
                }
            } );

            while( defined( my $code = shift( @stack ) ) ) {

                $code -> ();
            }

            undef @stack;
        },
    } );

    $self -> { 'pid' } = Salvation::DaemonDecl::Backend
        -> spawn_worker( $daemondecl_meta, 'http server' );
}

1;

__END__
