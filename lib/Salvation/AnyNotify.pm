package Salvation::AnyNotify;

use strict;
use warnings;

use base 'Salvation::PluginCore';

use Salvation::Method::Signatures;
use Salvation::DaemonDecl::Backend ();

our $VERSION = 0.01;
our $AUTOLOAD;

sub AUTOLOAD {

    my ( $self, @args ) = @_;
    my $autoload = $AUTOLOAD;

    return $self -> { $autoload } if exists $self -> { $autoload };

    my $plugin = ( $autoload =~ m/^.*::(.+?)$/ )[ 0 ];
    my $object = $self -> load_plugin( infix => 'Plugin', base_name => $plugin );

    die( "Failed to load plugin: ${plugin}" ) unless defined $object;

    return $self -> { $autoload } = $object;
}

method daemondecl_meta() {

    return Salvation::DaemonDecl::Backend -> get_meta( ref( $self ) || $self );
}

1;

__END__
