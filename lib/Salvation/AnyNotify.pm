package Salvation::AnyNotify;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Object';

use Module::Load 'load';
use Scalar::Util 'weaken';
use Salvation::TC ();
use String::CamelCase 'camelize';
use Salvation::Method::Signatures;
use Salvation::DaemonDecl::Backend ();

our $VERSION = 0.01;
our $AUTOLOAD;

sub AUTOLOAD {

    my ( $self, @args ) = @_;

    return $self -> { $AUTOLOAD } if exists $self -> { $AUTOLOAD };

    my $plugin = camelize( ( $AUTOLOAD =~ m/^.*::(.+?)$/ )[ 0 ] );
    my $object = $self -> load_plugin( infix => 'Plugin', base_name => $plugin );

    die( "Failed to load plugin: ${plugin}" ) unless defined $object;

    return $self -> { $AUTOLOAD } = $object;
}

method load_plugin( Str{1,} :infix!, Str{1,} :base_name! ) {

    foreach my $class ( @{ $self -> linearized_isa() } ) {

        my $base_class = "${class}::${infix}";
        my $plugin = "${base_class}::${base_name}";

        if( eval{ load $plugin; 1 } ) {

            weaken( my $weak = $self );

            $plugin = $plugin -> new( core => $weak );
            Salvation::TC -> assert( $plugin, $base_class );

            return $plugin;
        }
    }

    return undef;
}

method daemondecl_meta() {

    return Salvation::DaemonDecl::Backend -> get_meta( ref( $self ) || $self );
}

method linearized_isa() {

    return $self -> { 'linearized_isa' } if exists $self -> { 'linearized_isa' };

    my @out = ();
    my %seen = ();
    my @stack = ( ( ref( $self ) || $self ) );

    while( defined( my $class = shift( @stack ) ) ) {

        next if $seen{ $class } ++;

        push( @out, $class );

        my $isa = "${class}::ISA";

        no strict 'refs';

        push( @stack, @{ *$isa } );
    }

    return $self -> { 'linearized_isa' } = \@out;
}

1;

__END__
