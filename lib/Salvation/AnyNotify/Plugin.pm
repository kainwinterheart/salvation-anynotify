package Salvation::AnyNotify::Plugin;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Object';

use Salvation::Method::Signatures;

sub start {};

method new( Salvation::AnyNotify :core! ) {

    $self = $self -> SUPER::new();
    $self -> { 'core' } = $core;

    $self -> start();

    return $self;
}

method core() {

    return $self -> { 'core' };
}

1;

__END__
