package ThaiSchema::Base;
use strict;
use warnings;
use utf8;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless { %args }, $class;
}

1;

