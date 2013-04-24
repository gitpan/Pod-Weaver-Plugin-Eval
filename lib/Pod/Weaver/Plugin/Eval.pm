package Pod::Weaver::Plugin::Eval;

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::Section';

use List::Util qw(first);
use Module::Load;
use Pod::Elemental;
use Pod::Elemental::Element::Nested;

our $VERSION = '0.01'; # VERSION

# regex
has include_modules => (
    is => 'rw',
    isa => 'Str',
);
has include_files => (
    is => 'rw',
    isa => 'Str',
);
has code => (
    is => 'rw',
    isa => 'Str',
);
#has _compiled_code => (
#    is => 'rw',
#);

sub weave_section {
    my ($self, $document, $input) = @_;

    # only compile code once
    if (!$self->{_compiled_code}) {
        my $code = $self->code;
        die "Please specify code" unless $code;
        $self->log_debug(["compiling code ..."]);
        $code = "sub { $code }" unless $code =~ /^\s*sub\s*\{/s;
        eval "\$self->{_compiled_code} = $code";
        die "Can't compile code '$code': $@" if $@;
    }

    my $filename = $input->{filename} || 'file';

    # select file
    my ($package, $ext);
    if ($filename =~ m!^lib/(.+)\.(pod|pm)$!) {
        $package = $1;
        $ext = $2;
        $package =~ s!/!::!g;

    } else {
        $self->log_debug(["skipped file %s (not a Perl module)", $filename]);
        return;
    }
    if (defined $self->include_files) {
        my $re = $self->include_files;
        eval { $re = qr/$re/ };
        $@ and die "Invalid regex in include_files: $re ($@)";
        unless ($filename =~ $re) {
            $self->log_debug(["skipped file %s (doesn't match exclude_files)",
                              $filename]);
            return;
        }
    }
    if (defined $self->include_modules) {
        my $re = $self->include_modules;
        eval { $re = qr/$re/ };
        $@ and die "Invalid regex in include_modules: $re ($@)";
        unless ($package =~ $re) {
            $self->log (["skipped package %s (doesn't match exclude_modules)",
                         $package]);
            return;
        }
    }

    local @INC = ("lib", @INC);
    if ($ext eq 'pm') {
        $self->log_debug(["loading module %s", $package]);
        load $package;
    }

    # run code
    $self->log_debug(["loading module %s", $package]);
    my %args = (
        args     => \@_,
        document => $document,
        input    => $input,
        filename => $filename,
        package  => $package,
        module   => $package, # synonym
    );
    $self->{_compiled_code}->($self, %args);
}

1;
# ABSTRACT: Evaluate code


__END__
=pod

=head1 NAME

Pod::Weaver::Plugin::Eval - Evaluate code

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your C<weaver.ini>:

 [-Eval]
 include_modules = ^Foo::Bar$
 ;include_files  = REGEX
 code = sub { my ($self, %args)=@_; my $document = $args{document}; push @{$document->children}, ... }

=head1 DESCRIPTION

This plugin load modules and evaluates Perl code. It can be used to extract
stuffs from the module (like some configuration or hash keys) and insert it to
the POD.

I first created this module to insert list of border styles and color themes
contained in C<%border_styles> package variable in
C<Text::ANSITable::BorderStyle::*> modules and C<%color_themes> variable in
C<Text::ANSITable::ColorTheme::*> modules.

Yes, it's a dirty (and ugly) hack. But it's quick :-)

=for Pod::Coverage weave_section

=head1 CONFIGURATION

=head2 include_files => STR

Value should be a regex, e.g. C</Foo/Bar/>.

=head2 include_modules => REGEX

Value should be a regex, e.g. C<^Foo::Bar$>.

=head2 code => STR

Should be something like:

 sub { my ($self, %args) = @_; ... }

C<sub {> and C<}> will be added if code does not have it. Code will be called
with C<%args> containing these keys:

=over

=item * filename => STR

=item * package => STR

=item * args => ARRAY

The original C<@_> passed to weave_section(). Note that weave_section() is
passed:

 ($self, $document, $input)

=item * document => OBJ

Document object passed to weave_section(). This is the output POD we are
building and this is what we're mostly interested in, usually. It can also be
retrieved from C<args>.

=item * input => OBJ

The input object passed to weave_section(). It contains information about the
input (original) document. Can also be retrieved from C<args>.

=back

=head1 SEE ALSO

L<Pod::Weaver>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

