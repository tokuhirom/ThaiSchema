package ThaiSchema;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.01';
use parent qw/Exporter/;

our $STRICT = 0;
our $ALLOW_EXTRA = 0;
our @ERRORS;
our $NAMESPACE = '';

our @EXPORT = qw/
    match_schema
    type_int type_str type_number type_hash type_array type_maybe type_bool
/;

use JSON;
use B;
use Data::Dumper;

use Scalar::Util qw/blessed/;

sub match_schema {
    local @ERRORS;
    local $NAMESPACE = '';
    my $ok = _match_schema(@_);
    return wantarray ? ($ok, \@ERRORS) : $ok;
}

sub _match_schema {
    my ($value, $schema) = @_;
    if (ref $schema eq 'HASH') {
        $schema = ThaiSchema::Hash->new($schema);
#       my $fail = 0;
#       my %rest_keys = map { $_ => 1 } keys %$value;
#       for my $key (keys %$schema) {
#           match_schema($value->{$key}, $schema->{$key}) or $fail++;
#           delete $rest_keys{$key};
#       }
#       return 0 if %rest_keys; # rest keys
#       return !$fail;
    }
    if (blessed $schema && $schema->can('match')) {
        if ($schema->match($value)) {
            return 1;
        } else {
            if ($schema->error) {
                push @ERRORS, $NAMESPACE .' '. $schema->error();
            }
            return 0;
        }
    } else {
        die "Unsupported schema: " . ref $schema;
    }
}

sub type_str() {
    ThaiSchema::Str->new();
}

sub type_int() {
    ThaiSchema::Int->new();
}

sub type_maybe($) {
    ThaiSchema::Maybe->new(shift);
}

sub type_number() {
    ThaiSchema::Number->new();
}

sub type_hash($) {
    ThaiSchema::Hash->new(shift);
}

sub type_array(;$) {
    ThaiSchema::Array->new(shift);
}

sub type_bool() {
    ThaiSchema::Bool->new()
}

package ThaiSchema::Hash;

sub new {
    my $class = shift;
    bless [$_[0]], $class;
}

sub match {
    my ($self, $value) = @_;
    return 0 unless ref $value eq 'HASH';

    my $schema = $self->[0];

    my $fail = 0;
    my %rest_keys = map { $_ => 1 } keys %$value;
    for my $key (keys %$schema) {
        local $NAMESPACE = $NAMESPACE ? "$NAMESPACE.$key" : $key;
        my $cs = $schema->{$key};
        if (ref $cs eq 'HASH') {
            $cs = ThaiSchema::Hash->new($cs);
        }
        if (not $cs->match($value->{$key})) {
            $fail++;
            if ($cs->error) {
                push @ERRORS, $NAMESPACE . ' ' . $cs->error();
            }
        }
        delete $rest_keys{$key};
    }
    if (%rest_keys && !$ThaiSchema::ALLOW_EXTRA) {
        push @ERRORS, 'have extra keys';
        return 0;
    }
    return !$fail;
}

sub error {
    return ();
}

package ThaiSchema::Array {
    sub new {
        my $class = shift;
        bless [$_[0]], $class;
    }
    sub match {
        my ($self, $value) = @_;
        return 0 unless ref $value eq 'ARRAY';
        if (defined $self->[0]) {
            for (my $i=0; $i<@{$value}; $i++) {
                local $NAMESPACE = $NAMESPACE . "[$i]";
                my $elem = $value->[$i];
                return 0 unless ThaiSchema::_match_schema($elem, $self->[0]);
            }
        }
        return 1;
    }
    sub error {
        return ();
    }
}

package ThaiSchema::Maybe {
    sub new {
        my $class = shift;
        bless [$_[0]], $class;
    }
    sub match {
        my ($self, $value) = @_;
        return 1 unless defined $value;
        return $self->[0]->match($value);
    }
}

package ThaiSchema::Str {
    sub new {
        my $class = shift;
        bless {}, $class;
    }
    sub match {
        my ($self, $value) = @_;
        return 0 unless defined $value;
        if ($ThaiSchema::STRICT) {
            my $b_obj = B::svref_2object(\$value);
            my $flags = $b_obj->FLAGS;
            return 0 if $flags & ( B::SVp_IOK | B::SVp_NOK ) and !( $flags & B::SVp_POK ); # SvTYPE is IV or NV?
            return 1;
        } else {
            return not ref $value;
        }
    }
    sub error {
        " is not str";
    }
}

package ThaiSchema::Int {
    sub new {
        my $class = shift;
        bless {}, $class;
    }
    sub match {
        my ($self, $value) = @_;
        return 0 unless defined $value;
        if ($ThaiSchema::STRICT) {
            my $b_obj = B::svref_2object(\$value);
            my $flags = $b_obj->FLAGS;
            return 1 if $flags & ( B::SVp_IOK | B::SVp_NOK ) and int($value) == $value and !( $flags & B::SVp_POK ); # SvTYPE is IV or NV?
            return 0;
        } else {
            return $value =~ /^[1-9][0-9]*$/;
        }
    }
    sub error {
        "is not int";
    }
}

package ThaiSchema::Number {
    use Scalar::Util ();
    sub new {
        my $class = shift;
        bless {}, $class;
    }
    sub match {
        my ($self, $value) = @_;
        return 0 unless defined $value;
        if ($ThaiSchema::STRICT) {
            my $b_obj = B::svref_2object(\$value);
            my $flags = $b_obj->FLAGS;
            return 1 if $flags & ( B::SVp_IOK | B::SVp_NOK ) and !( $flags & B::SVp_POK ); # SvTYPE is IV or NV?
            return 0;
        } else {
            return Scalar::Util::looks_like_number($value);
        }
    }
}

package ThaiSchema::Bool {
    use JSON;
    sub new {
        my $class = shift;
        bless {}, $class;
    }
    sub match {
        my ($self, $value) = @_;
        return 0 unless defined $value;
        return 1 if JSON::is_bool($value);
        return 1 if ref($value) eq 'SCALAR' && ($$value eq 1 || $$value eq 0);
        return 0;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

ThaiSchema - ...

=head1 SYNOPSIS

  use ThaiSchema;

=head1 DESCRIPTION

ThaiSchema is

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
